# Firestore collections – POS app

Your app expects these **top-level collections**. You currently have **shop** and **users**. Here’s what to fix and what will appear as you use the app.

---

## Collection name: **shop** vs **shops**

- Your database has a collection named **shop** (singular).
- The app uses **shops** (plural) everywhere (Create Shop, Create Admin, list shops).
- So the app **will not see** the document you have under **shop**.

**What to do:**

1. In Firestore, click **+ Start collection**.
2. Collection ID: **`shops`** (plural).
3. Add a document. You can use:
   - **Document ID:** `shop1` (or any ID; your users reference `shopId: "shop1"`).
   - **Fields:**

     | Field      | Type     | Value example   |
     |-----------|----------|------------------|
     | `shopId`  | string   | `shop1`          |
     | `name`    | string   | `My Fruit shop`  |
     | `status`  | string   | `Active`         |
     | `address` | string   | (your address)   |
     | `createdAt` | timestamp | (optional)    |

4. Save. You can keep or delete the old **shop** collection later.

---

## Collections your app uses

| Collection     | You have? | Created by app? | What to do |
|----------------|-----------|------------------|------------|
| **shops**      | No (you have **shop**) | Yes (Create Shop) | **Create `shops`** and add at least one shop doc (e.g. shop1) as above. |
| **users**      | Yes       | Partly (Auth + app) | OK. Keep as is; ensure fields: `userId`, `email`, `name`, `role`, `shopId`, `status`, `phone`, `createdAt`. |
| **orders**     | No        | Yes (when sale is completed) | No need to create; app creates when orders are placed. **Create composite indexes** (see below). |
| **order_items**| No        | Yes (with each order) | No need to create; app creates. |
| **products**   | No        | Yes (Admin adds products) | No need to create; app creates. **Create composite indexes**. |
| **settings**   | No        | Yes (Admin saves settings) | No need to create; app creates. **Create composite indexes**. |
| **expenses**   | No        | Yes (Admin adds expenses) | No need to create; app creates. **Create composite indexes**. |
| **audit_logs** | No        | Yes (app logs actions) | No need to create; app creates. **Create composite indexes**. |
| **customers**  | No        | Yes (from POS/payment) | No need to create; app creates. |
| **categories** | No        | Yes (if you use categories in POS) | No need to create; app creates when needed. |

---

## You do **not** need to pre-create empty collections

Firestore creates a collection when the **first document** is written. So:

- **orders**, **products**, **settings**, **expenses**, **audit_logs**, **customers**, **categories** will appear automatically when the app writes to them.
- You **must**:
  1. Add the **shops** collection and at least one shop document so the app can list shops and assign users to `shop1`.
  2. Create the **composite indexes** so queries don’t fail with “The query requires an index”.

---

## Composite indexes (required for queries)

In Firestore go to **Indexes** → **Composite** and create indexes (or use the links from the app’s error messages when you run it):

- **orders:** `orderStatus` (Asc), `shopId` (Asc), `createdAt` (Desc) — and/or `shopId` (Asc), `createdAt` (Desc) depending on queries.
- **settings:** `scope` (Asc), `shopId` (Asc), `key` (Asc).
- **products:** `shopId` (Asc), `name` (Asc).
- **users:** `shopId` (Asc), `role` (Asc), `name` (Asc).
- **expenses:** `shopId` (Asc), `createdAt` (Desc).
- **audit_logs:** `shopId` (Asc), `timestamp` (Desc).
- **shops:** `name` (Asc) — for “list shops” in Create Admin.

---

## Small fix in your existing shop document

In your current **shop** document you have a field **`addresss`** (three s). If you copy that into **shops**, use **`address`** (two s) so it matches what the app may expect later.

---

## Summary

1. **Create collection `shops`** and add one document (e.g. document ID `shop1`) with at least `shopId`, `name`, `status`, and optionally `address`, `createdAt`.
2. **Keep `users`** as is.
3. **Do not** create empty collections for orders, products, settings, expenses, audit_logs — the app will create them when it writes data.
4. **Create the composite indexes** (via Firestore **Indexes** or the URLs in the app’s run logs) so all queries succeed.

After that, your Firestore structure is aligned with the app.
