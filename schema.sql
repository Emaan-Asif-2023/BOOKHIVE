DROP TABLE IF EXISTS Users;
CREATE TABLE Users (
    username TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    description TEXT,
    noOfBooksRead INTEGER DEFAULT 0
);
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
    bookname TEXT PRIMARY KEY,
    author TEXT NOT NULL,
    genre TEXT,
    year INTEGER,
    description TEXT,
    averageRating REAL DEFAULT 0,
    noOfRatings INTEGER DEFAULT 0,
    cover_url TEXT
);
DROP TABLE IF EXISTS Ratings;
CREATE TABLE Ratings (
    username TEXT,
    bookname TEXT,
    stars INTEGER CHECK (stars BETWEEN 1 AND 5),
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS Reviews;
CREATE TABLE Reviews (
    username TEXT,
    bookname TEXT,
    review TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS Followers;
CREATE TABLE Followers (
    follower TEXT,
    followee TEXT,
    PRIMARY KEY (follower, followee),
    FOREIGN KEY (follower) REFERENCES Users(username),
    FOREIGN KEY (followee) REFERENCES Users(username)
);
DROP TABLE IF EXISTS Friends;
CREATE TABLE Friends (
    user1 TEXT,
    user2 TEXT,
    PRIMARY KEY (user1, user2),
    FOREIGN KEY (user1) REFERENCES Users(username),
    FOREIGN KEY (user2) REFERENCES Users(username)
);
DROP TABLE IF EXISTS ReadBooksList;
CREATE TABLE ReadBooksList (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS WishlistBooks;
CREATE TABLE WishlistBooks (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS CurrentlyReadingBooks;
CREATE TABLE CurrentlyReadingBooks (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS LikedBooksList;
CREATE TABLE LikedBooksList (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS UserGraph;
CREATE TABLE UserGraph (
    username TEXT,
    bookname TEXT,
    ratingGiven INTEGER CHECK (ratingGiven BETWEEN 1 AND 5),
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);
DROP TABLE IF EXISTS BookGraph;
CREATE TABLE BookGraph (
    bookname TEXT,
    username TEXT,
    ratingReceived INTEGER CHECK (ratingReceived BETWEEN 1 AND 5),
    PRIMARY KEY (bookname, username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname),
    FOREIGN KEY (username) REFERENCES Users(username)
);

INSERT INTO Users (username, email, password, description, noOfBooksRead)
VALUES
    ('Ali', 'ali12@gmail.com', 'alipass456', 'Loves mystery novels', 5),
    ('Ahmed', 'ahmedN@gmail.com', 'ahmed4', 'Sci-fi enthusiast', 10),
    ('Rayan', 'rayxx@gmail.com', 'rayX', 'Enjoys historical fiction', 15),
    ('Azlan', 'azz@gmail.com', 'azlan67', 'Bookworm', 20);

INSERT INTO Books (bookname, author, genre, year, description, averageRating, noOfRatings, cover_url)
VALUES
    ('The Time Machine', 'H.G. Wells', 'Science Fiction', 1895, 'A scientist invents a machine to travel in time.', 4.2, 100, "https://covers.openlibrary.org/b/isbn/0866119833-S.jpg"),
    ('Pride and Prejudice', 'Jane Austen', 'Romance', 1813, 'A classic novel about manners and marriage.', 4.7, 150, "https://covers.openlibrary.org/b/isbn/0141439513-S.jpg"),
    ('The Da Vinci Code', 'Dan Brown', 'Thriller', 2003, 'A symbologist unravels a conspiracy in religious history.', 4.5, 200, "https://covers.openlibrary.org/b/isbn/0385504209-S.jpg");

INSERT INTO Ratings (username, bookname, stars)
VALUES
    ('Ali', 'The Da Vinci Code', 5),
    ('Ahmed', 'The Time Machine', 3),
    ('Rayan', 'Pride and Prejudice', 4);

INSERT INTO Reviews (username, bookname, review)
VALUES
    ('Ali', 'The Da Vinci Code', 'Thrilling and full of suspense.'),
    ('Ahmed', 'The Time Machine', 'Fascinating concept of time travel.'),
    ('Rayan', 'Pride and Prejudice', 'A beautifully written classic.');

INSERT INTO Followers (follower, followee)
VALUES
    ('Ali', 'Ahmed'),
    ('Ahmed', 'Rayan'),
    ('Rayan', 'Azlan');

INSERT INTO Friends (user1, user2)
VALUES
    ('Ali', 'Rayan'),
    ('Ahmed', 'Azlan');

INSERT INTO ReadBooksList (username, bookname)
VALUES
    ('Ali', 'The Da Vinci Code'),
    ('Ahmed', 'The Time Machine');

INSERT INTO WishlistBooks (username, bookname)
VALUES
    ('Azlan', 'The Da Vinci Code'),
    ('Ali', 'Pride and Prejudice');

INSERT INTO CurrentlyReadingBooks (username, bookname)
VALUES
    ('Ahmed', 'Pride and Prejudice'),
    ('Rayan', 'The Time Machine');

INSERT INTO LikedBooksList (username, bookname)
VALUES
    ('Ali', 'The Da Vinci Code'),
    ('Rayan', 'Pride and Prejudice');

INSERT INTO UserGraph (username, bookname, ratingGiven)
VALUES
    ('Ali', 'The Da Vinci Code', 5),
    ('Ahmed', 'The Time Machine', 4);

INSERT INTO BookGraph (bookname, username, ratingReceived)
VALUES
    ('The Da Vinci Code', 'Ali', 5),
    ('The Time Machine', 'Ahmed', 4);