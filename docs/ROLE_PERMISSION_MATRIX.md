# Role–Permission Verification Matrix

Based on Firestore security rules. All access requires authenticated, active user. Scoping (e.g. same shop, own doc) is implied where applicable.

| Collection       | SuperAdmin              | Admin                   | Employee                | Viewer                  |
|-----------------|-------------------------|-------------------------|-------------------------|-------------------------|
| **users**       | Read / Write / Delete   | Read / Write / Denied   | Read (own) / Denied / Denied | Denied / Denied / Denied |
| **shops**       | Read / Write / Delete   | Read / Denied / Denied  | Denied / Denied / Denied | Denied / Denied / Denied |
| **products**    | Read / Write / Denied   | Read / Write / Denied   | Read / Denied / Denied  | Read / Denied / Denied  |
| **orders**      | Read / Denied / Denied  | Read / Denied / Denied  | Read / Write / Denied   | Read / Denied / Denied  |
| **order_items** | Read / Denied / Denied  | Read / Denied / Denied  | Read / Write / Denied   | Read / Denied / Denied  |
| **customers**   | Read / Write / Denied   | Read / Write / Denied   | Denied / Write / Denied | Read / Denied / Denied  |
| **expenses**    | Read / Denied / Denied  | Read / Denied / Denied  | Denied / Denied / Denied | Read / Denied / Denied  |
| **inventory_logs** | Read / Denied / Denied | Read / Denied / Denied  | Denied / Denied / Denied | Denied / Denied / Denied |
| **audit_logs**  | Read / Denied / Denied  | Read / Denied / Denied  | Denied / Denied / Denied | Denied / Denied / Denied |
| **settings**    | Read / Write / Delete   | Read / Write / Denied   | Denied / Denied / Denied | Denied / Denied / Denied |

**Legend**

- **Read** — allowed (scoped by role: same shop, own document, or all where applicable).
- **Write** — Create and/or Update allowed (scoped by role).
- **Delete** — Delete allowed (only where rules allow).
- **Denied** — that operation is not allowed for that role on that collection.

**Notes**

- **users:** Admin can only create/update employees in the same shop; cannot delete. Employee can read only their own user document.
- **products:** Client write cannot change `stock`; delete is denied for all (product delete disabled).
- **orders / order_items:** Only Employee can create/update (orders: create + update when not locked); delete denied for all. Employee update is limited to own, pending orders.
- **customers:** Employee has no read; can create (e.g. during billing). Delete denied for all.
- **expenses / inventory_logs / audit_logs:** No client write or delete; writes only via Cloud Functions (Admin SDK).
- **settings:** Admin can read/write only shop-scoped settings; SuperAdmin can delete.
