CREATE DATABASE library_management;
USE library_management;


----- CREATE TABLE BOOK-----
CREATE TABLE books(
isbn VARCHAR(50) PRIMARY KEY,
book_title VARCHAR(60),
category VARCHAR(50),
rental_price FLOAT,
status VARCHAR(50),
author VARCHAR(50),
publisher VARCHAR(50));

----- CREATE TABLE BRANCH-----
CREATE TABLE branch(
branch_id VARCHAR(15) PRIMARY KEY,
manager_id VARCHAR(15),
branch_address VARCHAR(20),
contact_no VARCHAR(20));


----- CREATE TABLE EMPLOYEES-----
CREATE TABLE employees(
emp_id VARCHAR(15) PRIMARY KEY,
emp_name VARCHAR(25),
position VARCHAR(15),
salary INT,
branch_id VARCHAR(15),
FOREIGN KEY (branch_id)
references branch(branch_id));

----- CREATE TABLE MEMBERS-----
CREATE TABLE members(
member_id VARCHAR(20) PRIMARY KEY,
member_name VARCHAR(20),
member_address VARCHAR(20),
reg_date VARCHAR(20));

----- CREATE TABLE ISSUED_STATUS-----
CREATE TABLE issued_status(
issued_id VARCHAR(25) PRIMARY KEY,
issued_member_id VARCHAR(25),
issued_book_name VARCHAR(60),
issued_date DATE,
issued_book_isbn VARCHAR(50),
issued_emp_id VARCHAR(20),
FOREIGN KEY (issued_book_isbn)
references books(isbn),
FOREIGN KEY (issued_emp_id)
references employees(emp_id),
FOREIGN KEY (issued_member_id)
references members(member_id));



----- create TABLE RETURN_STATUS----
CREATE TABLE return_status(
return_id VARCHAR(10) PRIMARY KEY,
issued_id VARCHAR(10),
return_book_name VARCHAR(10),
return_date DATE,
return_book_isbn VARCHAR(10),
FOREIGN KEY (return_book_isbn)
references books(isbn));


------ Data Analysis ------

----- Task 1. Create a New Book Record -- '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn , book_title, category, rental_price, status, author, publisher) 
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

----- Task 2: Update an Existing Member's Address

UPDATE members 
SET member_address = '1234567898'
WHERE member_id = 'C102';

----- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS107' from the issued_status table.

DELETE from issued_status
where issued_id = 'IS107';

----- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT issued_book_name,issued_emp_id FROM issued_status 
WHERE issued_emp_id = 'E101'
GROUP BY 1;

----- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id, COUNT(*) FROM issued_status 
GROUP BY 1
HAVING COUNT(*) >1 ;

----- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issue_count AS
SELECT bk.isbn, bk.book_title, COUNT(ist.issued_id) as book_issue FROM issued_status as ist
JOIN books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY bk.isbn,bk.book_title;
SELECT * FROM  book_issue_count;

----- Task 7. Retrieve All Books in a Specific Category:

SELECT book_title from books
WHERE category = 'classic';

----- Task 8: Find Total Rental Income by Category:

SELECT bk.category,SUM(bk.rental_price), COUNT(*) FROM issued_status as ist
JOIN books as bk
ON bk.isbn = ist.issued_book_isbn
GROUP BY 1;

----- Task 9: List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= DATE_SUB(NOW(), INTERVAL 180 DAY);

----- Task 10: List Employees with Their Branch Manager's Name and their branch details:

SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id;


----- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

----- Task 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

----- Task 13: Identify Members with Overdue Books Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;


----- Task 14: Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table)

DELIMITER //
CREATE PROCEDURE ADD_RETURNR_ECORDS(p_return_id VARCHAR(10), p_issued_id VARCHAR(10))
BEGIN
DECLARE v_isbn VARCHAR(50);
DECLARE v_book_name VARCHAR(80);
INSERT INTO return_status(return_id, issued_id, return_date)
VALUES 
(p_return_id, p_issued_id, CURRENT_DATE);
    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
    SELECT 'Thank you for returning the book: %' AS NOTICE , v_book_name;
END
// DELIMITER ;

-- calling function 
CALL ADD_RETURNR_ECORDS('RS138', 'IS135');

-- calling function 
CALL ADD_RETURNR_ECORDS('RS148', 'IS140');



----- Task 15: Branch Performance Report Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;


----- Task 16: CTAS: Create a Table of Active Members Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT DISTINCT issued_member_id FROM issued_status WHERE 
                        issued_date >= NOW() - INTERVAL 2 MONTH);
SELECT * FROM active_members;

----- Task 17: Find Employees with the Most Book Issues Processed Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;



----- Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
DELIMITER // 
CREATE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
BEGIN

DECLARE v_status VARCHAR(10);
SELECT status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT 'Book records added successfully for book isbn : %' AS RAISE_NOTICE, p_issued_book_isbn;


    ELSE
        SELECT 'Sorry to inform you the book you have requested is unavailable book_isbn: %'AS RAISE_NOTICE, p_issued_book_isbn;
        END IF;
END
// DELIMITER ;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
