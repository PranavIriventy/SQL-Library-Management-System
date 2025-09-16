# SQL Library Management System

This is a **SQL-based Library Management System**.  
It allows you to manage books, authors, categories, library members, book copies, transactions (borrowing/returning), and reservations.  

---

## **Features**

- **Tables**:
  - `categories` – Book categories like Fiction, Science, etc.
  - `authors` – Information about book authors.
  - `books` – Details of books including category and author.
  - `book_copies` – Individual copies of books with status tracking.
  - `members` – Library members’ information.
  - `transactions` – Borrow and return transactions, including fines.
  - `reservations` – Track reserved books by members.

- **Stored Procedures**:
  - `borrow_book` – Automates borrowing a book.
  - `return_book` – Automates returning a book.

- **Trigger**:
  - `calculate_fine` – Automatically calculates fines for overdue books.

- **Views**:
  - `borrowed_books` – Shows currently borrowed books.
  - `overdue_books` – Shows overdue books with fines.
  - `member_activity` – Summary of each member's borrowings and fines.

---

## **How to Use**

1. Open **MySQL Workbench**.
2. Run the file `library_management_system.sql`.
3. Enjoy managing a library using SQL queries and procedures.

---

## **Sample Queries**

- Borrow a book:  
```sql
CALL borrow_book(1, 1, 14);

