DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db;
USE library_db;
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT
);
SHOW TABLES;
INSERT INTO categories (name, description) VALUES
('Computer Science', 'Books related to programming, software, and IT'),
('Fiction', 'Novels and storybooks for entertainment'),
('Science', 'Books related to Physics, Chemistry, Biology'),
('History', 'Books about historical events and figures');
SELECT * FROM categories;
CREATE TABLE authors (
  author_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  bio TEXT
);
SHOW TABLES;
INSERT INTO authors (name, bio) VALUES
('Robert C. Martin', 'Author of Clean Code and other programming books'),
('J.K. Rowling', 'Author of the Harry Potter series'),
('Isaac Asimov', 'Author of science fiction and popular science books');
SELECT * FROM authors;
CREATE TABLE books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  isbn VARCHAR(20) UNIQUE,
  publisher VARCHAR(255),
  publication_year INT,
  category_id INT,
  author_id INT,
  description TEXT,
  total_copies INT DEFAULT 0,
  FOREIGN KEY (category_id) REFERENCES categories(category_id),
  FOREIGN KEY (author_id) REFERENCES authors(author_id)
);
SHOW TABLES;
INSERT INTO books (title, isbn, publisher, publication_year, category_id, author_id, description, total_copies) VALUES
('Clean Code', '9780132350884', 'Prentice Hall', 2008, 1, 1, 'A handbook of agile software craftsmanship', 2),
('Harry Potter and the Philosopher''s Stone', '9780439554930', 'Bloomsbury', 1997, 2, 2, 'Fantasy novel about a young wizard', 3),
('Foundation', '9780553293357', 'Spectra', 1951, 3, 3, 'Classic science fiction novel', 2);
SELECT * FROM books;
CREATE TABLE book_copies (
  copy_id INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  shelf_location VARCHAR(100),
  barcode VARCHAR(100) UNIQUE,
  status ENUM('available','borrowed','reserved','lost','maintenance') DEFAULT 'available',
  FOREIGN KEY (book_id) REFERENCES books(book_id)
);
SHOW TABLES;
INSERT INTO book_copies (book_id, shelf_location, barcode, status) VALUES
(1, 'A1-01', 'BC1001', 'available'),
(1, 'A1-02', 'BC1002', 'available'),
(2, 'B2-01', 'BC2001', 'available'),
(2, 'B2-02', 'BC2002', 'available'),
(2, 'B2-03', 'BC2003', 'available'),
(3, 'C3-01', 'BC3001', 'available'),
(3, 'C3-02', 'BC3002', 'available');
SELECT * FROM book_copies;
CREATE TABLE members (
  member_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  address TEXT,
  joined_date DATETIME DEFAULT CURRENT_TIMESTAMP
);
SHOW TABLES;
INSERT INTO members (first_name, last_name, email, phone, address) VALUES
('Alice', 'Patel', 'alice@example.com', '999001122', 'Mumbai'),
('Bob', 'Sharma', 'bob@example.com', '888777666', 'Delhi'),
('Charlie', 'Gupta', 'charlie@example.com', '777888999', 'Bangalore');
SELECT * FROM members;
CREATE TABLE transactions (
  transaction_id INT AUTO_INCREMENT PRIMARY KEY,
  copy_id INT NOT NULL,
  member_id INT NOT NULL,
  borrow_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date DATETIME NOT NULL,
  return_date DATETIME,
  status ENUM('borrowed','returned','overdue','lost') DEFAULT 'borrowed',
  fine_amount DECIMAL(8,2) DEFAULT 0.00,
  FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id),
  FOREIGN KEY (member_id) REFERENCES members(member_id)
);
SHOW TABLES;
-- Member 1 borrows copy 1 for 14 days
INSERT INTO transactions (copy_id, member_id, due_date)
VALUES (1, 1, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 14 DAY));

-- Member 2 borrows copy 3 for 7 days
INSERT INTO transactions (copy_id, member_id, due_date)
VALUES (3, 2, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 7 DAY));
SELECT * FROM transactions;
CREATE TABLE reservations (
  reservation_id INT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  member_id INT NOT NULL,
  reserved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('waiting','notified','cancelled','fulfilled') DEFAULT 'waiting',
  FOREIGN KEY (book_id) REFERENCES books(book_id),
  FOREIGN KEY (member_id) REFERENCES members(member_id)
);
SHOW TABLES;
INSERT INTO reservations (book_id, member_id)
VALUES (2, 3);  -- Member 3 reserves "Harry Potter"

INSERT INTO reservations (book_id, member_id)
VALUES (3, 1);  -- Member 1 reserves "Foundation"
SELECT * FROM reservations;
DELIMITER //

CREATE PROCEDURE borrow_book(IN member INT, IN book INT, IN days INT)
BEGIN
    DECLARE copyid INT;

    -- Find an available copy
    SELECT copy_id INTO copyid
    FROM book_copies
    WHERE book_id = book AND status = 'available'
    LIMIT 1;

    -- If a copy is available, create transaction and update copy status
    IF copyid IS NOT NULL THEN
        INSERT INTO transactions (copy_id, member_id, borrow_date, due_date, status)
        VALUES (copyid, member, CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL days DAY), 'borrowed');

        UPDATE book_copies
        SET status = 'borrowed'
        WHERE copy_id = copyid;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available copy';
    END IF;
END;
//

DELIMITER ;
DELIMITER //

CREATE PROCEDURE return_book(IN trans_id INT)
BEGIN
    DECLARE copyid INT;

    -- Get the copy ID for the transaction
    SELECT copy_id INTO copyid FROM transactions WHERE transaction_id = trans_id;

    -- Update transaction and book copy
    UPDATE transactions
    SET return_date = CURRENT_TIMESTAMP, status = 'returned'
    WHERE transaction_id = trans_id;

    UPDATE book_copies
    SET status = 'available'
    WHERE copy_id = copyid;
END;
//

DELIMITER ;
CALL borrow_book(1, 1, 14);  -- Member 1 borrows Book 1 for 14 days
CALL return_book(1);  -- Return transaction with ID 1
DELIMITER //

CREATE TRIGGER calculate_fine
BEFORE UPDATE ON transactions
FOR EACH ROW
BEGIN
    -- Check if the book is being returned late
    IF NEW.return_date IS NOT NULL AND NEW.return_date > NEW.due_date THEN
        -- Calculate fine: 1 unit per day late
        SET NEW.fine_amount = DATEDIFF(NEW.return_date, NEW.due_date) * 1.00;
    END IF;
END;
//

DELIMITER ;
CALL borrow_book(1, 1, 7);  -- Member 1 borrows Book 1 for 7 days
UPDATE transactions
SET return_date = DATE_ADD(due_date, INTERVAL 3 DAY)
WHERE transaction_id = 1;
SELECT * FROM transactions WHERE transaction_id = 1;
CREATE VIEW borrowed_books AS
SELECT 
    t.transaction_id,
    m.first_name,
    m.last_name,
    b.title,
    c.copy_id,
    t.borrow_date,
    t.due_date
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN book_copies c ON t.copy_id = c.copy_id
JOIN books b ON c.book_id = b.book_id
WHERE t.status = 'borrowed';
CREATE VIEW overdue_books AS
SELECT 
    t.transaction_id,
    m.first_name,
    m.last_name,
    b.title,
    c.copy_id,
    t.borrow_date,
    t.due_date,
    DATEDIFF(CURRENT_DATE, t.due_date) AS days_overdue,
    t.fine_amount
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN book_copies c ON t.copy_id = c.copy_id
JOIN books b ON c.book_id = b.book_id
WHERE t.status = 'borrowed' AND t.due_date < CURRENT_DATE;
CREATE VIEW member_activity AS
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    COUNT(t.transaction_id) AS total_borrowed,
    SUM(t.fine_amount) AS total_fine
FROM members m
LEFT JOIN transactions t ON m.member_id = t.member_id
GROUP BY m.member_id, m.first_name, m.last_name;
SELECT * FROM borrowed_books;
SELECT * FROM overdue_books;
SELECT * FROM member_activity;
