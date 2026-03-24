You are a senior Flutter + Drift (Moor) expert.

I have a compilation failure in my Flutter project caused by inconsistencies between my Drift database schema, generated files, and usage in providers.

## 🔴 PROBLEM

The following errors are happening:

1. Missing getters in `WorkstationRecord`:

* faceEmbedding
* bodySignature
* assignedEmployeeId
* profileCapturedAt
* profileVersion

Example error:
The getter 'faceEmbedding' isn't defined for the type 'WorkstationRecord'

2. Type mismatch errors:
   Column<T> can't be assigned to GeneratedColumn<Object>

3. Companion errors:
   No named parameter with the name 'assignedEmployeeId'

---

## 📌 ROOT CAUSE

* Fields are being used in `kiosk_provider.dart` but are NOT defined in the Drift table
* The generated file `database.g.dart` is out of sync
* Some internal Drift APIs expect `GeneratedColumn<Object>` but receive `Column<T>`

---

## ✅ WHAT I NEED YOU TO DO

### 1. Fix the Drift table

Update the `WorkstationRecords` table in `database.dart` by adding the missing fields:

* assignedEmployeeId (String, nullable)
* faceEmbedding (String, nullable, JSON encoded list)
* bodySignature (String, nullable, JSON encoded map)
* profileCapturedAt (DateTime, nullable)
* profileVersion (int, default = 1)

Make sure the schema is correct and follows Drift best practices.

---

### 2. Ensure compatibility with generated code

* Update any insert/update methods using `WorkstationRecordsCompanion`
* Ensure all new fields are properly included

---

### 3. Fix type issues

Wherever a function expects `GeneratedColumn<Object>`, fix the type mismatch properly.

Preferred solution:

* Use correct Drift APIs instead of unsafe casting
* If casting is unavoidable, apply:
  (column as GeneratedColumn<Object>)

---

### 4. Regenerate code (IMPORTANT)

Assume I will run:

flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

So ensure your solution is compatible with code generation.

---

### 5. Validate usage in provider

Fix `kiosk_provider.dart` so that:

* JSON decoding works safely
* Null checks are correct
* Types are properly handled

Example expectations:

* faceEmbedding → List<double>
* bodySignature → Map<String, dynamic>

---

## ⚠️ CONSTRAINTS

* Do NOT break existing architecture
* Do NOT remove features
* Keep code clean and production-ready
* Follow best practices for Drift and Flutter

---

## 🎯 OUTPUT FORMAT

Provide:

1. ✅ Corrected `WorkstationRecords` table
2. ✅ Any required fixes in DAO / insert methods
3. ✅ Fixes for type errors
4. ✅ Fixed snippet of provider usage (if needed)

Make the solution COMPLETE and ready to paste.

---
