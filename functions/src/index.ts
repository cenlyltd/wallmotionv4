import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();

// ── Config (set via: firebase functions:config:set midtrans.server_key=xxx) ──
const MIDTRANS_SERVER_KEY = process.env.MIDTRANS_SERVER_KEY ?? "";
const MIDTRANS_ENV        = process.env.MIDTRANS_ENV ?? "sandbox";
const MIDTRANS_BASE_URL   = MIDTRANS_ENV === "production"
  ? "https://api.midtrans.com"
  : "https://api.sandbox.midtrans.com";
const TOKEN_HOURS         = parseInt(process.env.TOKEN_HOURS ?? "48");

// ── Helper ────────────────────────────────────────────────────────────────
function rupiah(n: number): string {
  return "Rp " + n.toLocaleString("id-ID");
}
function newToken(): string {
  return crypto.randomBytes(24).toString("hex");
}
function midtransAuth(): string {
  return Buffer.from(MIDTRANS_SERVER_KEY + ":").toString("base64");
}

// ══════════════════════════════════════════════════════════════════════════
// 1. createOrder — dipanggil dari Flutter app
// ══════════════════════════════════════════════════════════════════════════
export const createOrder = functions.https.onCall(
  { region: "asia-southeast1" },
  async (request) => {
    // Auth check
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
    }

    const { productId, buyerName, buyerEmail } = request.data;
    const userId = request.auth.uid;

    if (!productId || !buyerName) {
      throw new functions.https.HttpsError("invalid-argument", "Data tidak lengkap.");
    }

    // Get product
    const prodDoc = await db.collection("products").doc(productId).get();
    if (!prodDoc.exists || !prodDoc.data()?.active) {
      throw new functions.https.HttpsError("not-found", "Produk tidak ditemukan.");
    }
    const product = prodDoc.data()!;

    // Create Midtrans order ID
    const orderId  = `WM-${crypto.randomBytes(5).toString("hex").toUpperCase()}-${Date.now()}`;
    const accessToken = newToken();
    const tokenExpires = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + TOKEN_HOURS * 3600 * 1000)
    );

    // ── Midtrans QRIS charge ───────────────────────────────────────────
    const payload = {
      payment_type: "qris",
      transaction_details: {
        order_id:     orderId,
        gross_amount: product.price,
      },
      customer_details: {
        first_name: buyerName,
        email:      buyerEmail || undefined,
      },
      qris: { acquirer: "gopay" },
    };

    let qrisUrl   = "";
    let qrisExpires: admin.firestore.Timestamp | null = null;

    try {
      const res = await axios.post(
        `${MIDTRANS_BASE_URL}/v2/charge`,
        payload,
        {
          headers: {
            "Content-Type":  "application/json",
            "Accept":        "application/json",
            "Authorization": `Basic ${midtransAuth()}`,
          },
          timeout: 15000,
        }
      );
      const data = res.data;
      qrisUrl    = data.actions?.[0]?.url ?? data.qr_string ?? "";
      if (data.expiry_time) {
        qrisExpires = admin.firestore.Timestamp.fromDate(new Date(data.expiry_time));
      }
    } catch (err: any) {
      console.error("Midtrans error:", err.response?.data ?? err.message);
      throw new functions.https.HttpsError("internal", "Gagal membuat QRIS. Coba lagi.");
    }

    // ── Save order to Firestore ────────────────────────────────────────
    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      userId,
      productId,
      productName:     product.name,
      buyerName,
      buyerEmail:      buyerEmail || "",
      amount:          product.price,
      status:          "pending_payment",
      midtransOrderId: orderId,
      qrisUrl,
      qrisExpires,
      accessToken,
      tokenExpires,
      createdAt:       admin.firestore.FieldValue.serverTimestamp(),
      paidAt:          null,
    });

    return {
      orderId:  orderRef.id,
      qrisUrl,
      amount:   product.price,
      midtransOrderId: orderId,
    };
  }
);

// ══════════════════════════════════════════════════════════════════════════
// 2. midtransWebhook — dipanggil oleh Midtrans server
//    URL: https://asia-southeast1-PROJECT_ID.cloudfunctions.net/midtransWebhook
// ══════════════════════════════════════════════════════════════════════════
export const midtransWebhook = functions.https.onRequest(
  { region: "asia-southeast1" },
  async (req, res) => {
    if (req.method !== "POST") { res.status(405).send("Method Not Allowed"); return; }

    const data = req.body;
    const {
      order_id:           midtransOrderId,
      status_code:        statusCode,
      gross_amount:       grossAmount,
      signature_key:      incomingSignature,
      transaction_status: txStatus,
      fraud_status:       fraudStatus,
      transaction_id:     txId,
    } = data;

    // ── Verify signature ──────────────────────────────────────────────
    const expected = crypto
      .createHash("sha512")
      .update(midtransOrderId + statusCode + grossAmount + MIDTRANS_SERVER_KEY)
      .digest("hex");

    if (expected !== incomingSignature) {
      console.error("Signature mismatch:", midtransOrderId);
      res.status(403).send("Invalid signature");
      return;
    }

    // ── Find order ────────────────────────────────────────────────────
    const snap = await db.collection("orders")
      .where("midtransOrderId", "==", midtransOrderId)
      .limit(1)
      .get();

    if (snap.empty) {
      console.error("Order not found:", midtransOrderId);
      res.status(404).send("Order not found");
      return;
    }

    const orderRef = snap.docs[0].ref;
    const order    = snap.docs[0].data();

    const isPaid    = txStatus === "settlement" || (txStatus === "capture" && fraudStatus === "accept");
    const isFailed  = ["cancel", "deny", "failure"].includes(txStatus);
    const isExpired = txStatus === "expire";

    if (isPaid && order.status !== "paid") {
      await orderRef.update({
        status:        "paid",
        midtransTxId:  txId,
        paidAt:        admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log("Order paid:", midtransOrderId);

    } else if (isFailed) {
      await orderRef.update({ status: "failed" });
    } else if (isExpired) {
      await orderRef.update({ status: "expired" });
    }

    res.status(200).send("OK");
  }
);

// ══════════════════════════════════════════════════════════════════════════
// 3. getWallpaperUrl — generate signed URL untuk stream video
//    Tidak expose Storage path ke client
// ══════════════════════════════════════════════════════════════════════════
export const getWallpaperUrl = functions.https.onCall(
  { region: "asia-southeast1" },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
    }

    const { orderId } = request.data;
    const userId = request.auth.uid;

    const orderDoc = await db.collection("orders").doc(orderId).get();
    if (!orderDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Order tidak ditemukan.");
    }

    const order = orderDoc.data()!;

    // Validasi kepemilikan
    if (order.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Bukan order kamu.");
    }
    if (order.status !== "paid") {
      throw new functions.https.HttpsError("failed-precondition", "Belum lunas.");
    }
    if (order.tokenExpires && order.tokenExpires.toDate() < new Date()) {
      throw new functions.https.HttpsError("failed-precondition", "Akses sudah kadaluarsa.");
    }

    // Get product HD path
    const prodDoc = await db.collection("products").doc(order.productId).get();
    if (!prodDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Produk tidak ditemukan.");
    }

    const hdPath = prodDoc.data()!.hdStoragePath;
    if (!hdPath) {
      throw new functions.https.HttpsError("not-found", "File wallpaper belum tersedia.");
    }

    // Generate signed URL (valid 1 jam)
    const bucket = admin.storage().bucket();
    const file   = bucket.file(hdPath);
    const [url]  = await file.getSignedUrl({
      action:  "read",
      expires: Date.now() + 3600 * 1000,
    });

    return { url };
  }
);
