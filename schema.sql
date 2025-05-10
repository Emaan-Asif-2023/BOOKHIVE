DROP TABLE IF EXISTS BookRatingSummary;
DROP TABLE IF EXISTS UserRatingSummary;
DROP TABLE IF EXISTS BookGraph;
DROP TABLE IF EXISTS UserGraph;
DROP TABLE IF EXISTS LikedBooksList;
DROP TABLE IF EXISTS CurrentlyReadingBooks;
DROP TABLE IF EXISTS WishlistBooks;
DROP TABLE IF EXISTS ReadBooksList;
DROP TABLE IF EXISTS Follows;
DROP TABLE IF EXISTS Followers;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Ratings;
DROP TABLE IF EXISTS FolderBooks;
DROP TABLE IF EXISTS BookFolders;
DROP TABLE IF EXISTS BookRecommendations;
DROP TABLE IF EXISTS UserChallenges;
DROP TABLE IF EXISTS Challenges;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Notifications;

-- Users table
CREATE TABLE Users (
    username TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    description TEXT,
    noOfBooksRead INT DEFAULT 0,
    topPick1 TEXT,
    topPick2 TEXT,
    topPick3 TEXT
);

-- Books table
CREATE TABLE Books (
    bookname TEXT PRIMARY KEY,
    author TEXT NOT NULL,
    genre TEXT,
    year INT,
    description TEXT,
    averageRating FLOAT DEFAULT 0,
    noOfRatings INT DEFAULT 0,
    cover_url TEXT
);

-- Ratings table
CREATE TABLE Ratings (
    username TEXT,
    bookname TEXT,
    stars INT CHECK (stars BETWEEN 1 AND 5),
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- Reviews table
CREATE TABLE Reviews (
    username TEXT,
    bookname TEXT,
    review TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- Followers table
CREATE TABLE Followers (
    follower TEXT,
    followee TEXT,
    PRIMARY KEY (follower, followee),
    FOREIGN KEY (follower) REFERENCES Users(username),
    FOREIGN KEY (followee) REFERENCES Users(username)
);

-- Follows table
CREATE TABLE Follows (
    follower TEXT,
    followee TEXT,
    PRIMARY KEY (follower, followee),
    FOREIGN KEY (follower) REFERENCES Users(username),
    FOREIGN KEY (followee) REFERENCES Users(username)
);

-- ReadBooksList
CREATE TABLE ReadBooksList (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- WishlistBooks
CREATE TABLE WishlistBooks (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- CurrentlyReadingBooks
CREATE TABLE CurrentlyReadingBooks (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- LikedBooksList
CREATE TABLE LikedBooksList (
    username TEXT,
    bookname TEXT,
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- UserGraph
CREATE TABLE UserGraph (
    username TEXT,
    bookname TEXT,
    ratingGiven INT CHECK (ratingGiven BETWEEN 1 AND 5),
    PRIMARY KEY (username, bookname),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- BookGraph
CREATE TABLE BookGraph (
    bookname TEXT,
    username TEXT,
    ratingReceived INT CHECK (ratingReceived BETWEEN 1 AND 5),
    PRIMARY KEY (bookname, username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname),
    FOREIGN KEY (username) REFERENCES Users(username)
);

-- BookRatingSummary
CREATE TABLE BookRatingSummary (
    bookname TEXT,
    stars INT CHECK (stars BETWEEN 1 AND 5),
    count INT DEFAULT 0,
    PRIMARY KEY (bookname, stars),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- UserRatingSummary
CREATE TABLE UserRatingSummary (
    username TEXT,
    stars INT CHECK (stars BETWEEN 1 AND 5),
    count INT DEFAULT 0,
    PRIMARY KEY (username, stars),
    FOREIGN KEY (username) REFERENCES Users(username)
);

-- BookRecommendations
CREATE TABLE BookRecommendations (
    recommender TEXT,
    receiver TEXT,
    bookname TEXT,
    message TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (recommender, receiver, bookname),
    FOREIGN KEY (recommender) REFERENCES Users(username),
    FOREIGN KEY (receiver) REFERENCES Users(username),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- BookFolders
CREATE TABLE BookFolders (
    folder_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    folder_name TEXT,
    FOREIGN KEY (username) REFERENCES Users(username)
);

-- FolderBooks
CREATE TABLE FolderBooks (
    folder_id INTEGER,
    bookname TEXT,
    PRIMARY KEY (folder_id, bookname),
    FOREIGN KEY (folder_id) REFERENCES BookFolders(folder_id),
    FOREIGN KEY (bookname) REFERENCES Books(bookname)
);

-- Challenges
CREATE TABLE Challenges (
    challenge_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    goal INT
);

-- UserChallenges
CREATE TABLE UserChallenges (
    username TEXT,
    challenge_id INTEGER,
    progress INT DEFAULT 0,
    completed INTEGER DEFAULT 0,
    badge_url TEXT,
    PRIMARY KEY (username, challenge_id),
    FOREIGN KEY (username) REFERENCES Users(username),
    FOREIGN KEY (challenge_id) REFERENCES Challenges(challenge_id)
);

--Notifications
CREATE TABLE Notifications (
    notificationID INTEGER PRIMARY KEY AUTOINCREMENT,
    sendby TEXT,
    sendto TEXT,
    message TEXT,
    FOREIGN KEY (sendby) REFERENCES Users(username),
    FOREIGN KEY (sendto) REFERENCES Users(username)
);

-- Trigger on bookgraph
CREATE TRIGGER trg_update_book_rating_summary
AFTER INSERT ON BookGraph
BEGIN
    UPDATE BookRatingSummary
    SET count = count + 1
    WHERE bookname = NEW.bookname AND stars = NEW.ratingReceived;

    -- If no such record exists, insert a new row with the rating
    INSERT OR IGNORE INTO BookRatingSummary (bookname, stars, count)
    VALUES (NEW.bookname, NEW.ratingReceived, 1);
END;

-- Trigger on usergraph
CREATE TRIGGER trg_update_user_rating_summary
AFTER INSERT ON UserGraph
BEGIN
    -- First, try to update the count if the user already has a rating for that star
    UPDATE UserRatingSummary
    SET count = count + 1
    WHERE username = NEW.username AND stars = NEW.ratingGiven;

    -- If no such record exists, insert a new row with the rating
    INSERT OR IGNORE INTO UserRatingSummary (username, stars, count)
    VALUES (NEW.username, NEW.ratingGiven, 1);
END;



INSERT INTO Users (username, email, password, description, noOfBooksRead, topPick1, topPick2, topPick3) VALUES
('Ali', 'ali12@gmail.com', 'alipass456', 'Loves mystery novels', 5, 'The Da Vinci Code', 'Inferno', 'Angels & Demons'),
('Ahmed', 'ahmedN@gmail.com', 'ahmed4', 'Sci-fi enthusiast', 10, 'The Time Machine', '1984', 'Dune'),
('Rayan', 'rayxx@gmail.com', 'rayX', 'Enjoys historical fiction', 15, 'Pride and Prejudice', 'War and Peace', 'Les Misérables'),
('Azlan', 'azz@gmail.com', 'azlan67', 'Bookworm', 20, 'The Hobbit', 'The Alchemist', 'To Kill a Mockingbird'),
('Fatima', 'fats@gmail.com', 'fatpass1', 'Romantic novels are life', 12, 'Pride and Prejudice', 'Emma', 'Sense and Sensibility'),
('Zoya', 'zoya_zee@gmail.com', 'zo123', 'Thriller junkie', 7, 'Gone Girl', 'The Girl on the Train', 'Sharp Objects'),
('Bilal', 'biloo99@gmail.com', 'bilalpass', 'Fantasy lover', 18, 'Harry Potter and the Sorcerers Stone', 'The Hobbit', 'Eragon'),
('Usman', 'usman_tor@gmail.com', 'usm@123', 'Deep thinker', 3, 'Sapiens', 'The Alchemist', '1984'),
('Areeba', 'areeba_q@gmail.com', 'areeba456', 'Reads everything!', 22, 'To Kill a Mockingbird', 'The Great Gatsby', 'Frankenstein'),
('Taha', 'tahaxx@gmail.com', 'taha000', 'New to reading', 2, 'The Little Prince', 'The Giver', 'Charlottes Web'),
('Noor', 'noorsun@gmail.com', 'noorpass', 'Fantasy & magic', 14, 'Harry Potter and the Goblet of Fire', 'The Lightning Thief', 'The Chronicles of Narnia'),
('Daniyal', 'dani12@gmail.com', 'dpass77', 'Classic collector', 30, 'War and Peace', '1984', 'Crime and Punishment');



INSERT INTO Books (bookname, author, genre, year, description, averageRating, noOfRatings, cover_url)
VALUES
    ('The Time Machine', 'H.G. Wells', 'Science Fiction', 1895, 'A scientist invents a machine to travel in time.', 4.2, 100, "https://covers.openlibrary.org/b/isbn/0866119833-L.jpg"),
    ('Pride and Prejudice', 'Jane Austen', 'Romance', 1813, 'A classic novel about manners and marriage.', 4.7, 150, "https://covers.openlibrary.org/b/isbn/0141439513-L.jpg"),
    ('The Da Vinci Code', 'Dan Brown', 'Thriller', 2003, 'A symbologist unravels a conspiracy in religious history.', 4.5, 200, "https://covers.openlibrary.org/b/isbn/0385504209-L.jpg"),
    ('The Stranger', 'Albert Camus', 'Absurdism', 1949, 'The story follows Meursault, an indifferent settler in French Algeria, who, weeks after the funeral of his mother, kills an unnamed Arab man in Algiers.', 4.9, 300, "https://covers.openlibrary.org/b/isbn/2070360024-L.jpg"),
    ('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', 1925, 'A story about the American dream and the roaring twenties.', 4.3, 250, "https://covers.openlibrary.org/b/isbn/9780743273565-L.jpg"),
    ('1984', 'George Orwell', 'Dystopian', 1949, 'A dystopian novel set in a totalitarian society under constant surveillance.', 4.8, 400, "https://covers.openlibrary.org/b/isbn/0141036141-L.jpg"),
    ('Crime and Punishment', 'Fyodor Dostoevsky', 'Psychological Fiction', 1866, 'Raskolnikov, a destitute and desperate former student, wanders through the slums of St Petersburg and commits a random murder without remorse or regret', 4.9, 350, "https://covers.openlibrary.org/b/isbn/978-0679734505-L.jpg"),
    ('Metamorphosis', 'Franz Kafka', 'Surrealism', 1915, 'The story of Gregor Samsa, a young man who, after transforming overnight into a giant, beetle-like insect, becomes an object of disgrace to his family.', 4.8, 400, "https://covers.openlibrary.org/b/isbn/1578987857-L.jpg"),
    ('Harry Potter and the Sorcerers Stone', 'J.K. Rowling', 'Fantasy', 1997, 'A young wizard discovers his destiny.', 4.9, 500, 'https://covers.openlibrary.org/b/isbn/9780590353427-L.jpg'),
    ('To Kill a Mockingbird', 'Harper Lee', 'Fiction', 1960, 'A story of racial injustice in the Deep South.', 4.8, 300, 'https://covers.openlibrary.org/b/isbn/9780061120084-L.jpg'),
    ('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', 1937, 'Bilbo Baggins embarks on an unexpected journey.', 4.7, 400, 'https://covers.openlibrary.org/b/isbn/9780547928227-L.jpg'),
    ('Gone Girl', 'Gillian Flynn', 'Thriller', 2012, 'A wife goes missing and the husband is a suspect.', 4.3, 220, 'https://covers.openlibrary.org/b/isbn/9780307588371-L.jpg'),
    ('Sapiens', 'Yuval Noah Harari', 'Non-fiction', 2011, 'A brief history of humankind.', 4.4, 250, 'https://covers.openlibrary.org/b/isbn/9780062316097-L.jpg'),
    ('The Alchemist', 'Paulo Coelho', 'Adventure', 1988, 'A shepherd follows his dream to Egypt.', 4.5, 310, 'https://covers.openlibrary.org/b/isbn/9780061122415-L.jpg'),
    ('The Girl on the Train', 'Paula Hawkins', 'Thriller', 2015, 'A woman sees something shocking from a train.', 4.1, 210, 'https://covers.openlibrary.org/b/isbn/9781594633669-L.jpg'),
    ('The Little Prince', 'Antoine de Saint-Exupéry', 'Fable', 1943, 'A child prince visits planets in search of meaning.', 4.6, 150, 'https://covers.openlibrary.org/b/isbn/9780156012195-L.jpg'),
    ('Les Misérables', 'Victor Hugo', 'Historical Fiction', 1862, 'An ex-convict changes his life for good.', 4.7, 270, 'https://covers.openlibrary.org/b/isbn/9780451525260-L.jpg'),
    ('Charlottes Web', 'E.B. White', 'Children', 1952, 'A pig and a spider form a touching friendship.', 4.5, 190, 'https://covers.openlibrary.org/b/isbn/9780064410939-L.jpg'),
    ('Emma', 'Jane Austen', 'Romance', 1815, 'A young woman meddles in her friends love lives.', 4.4, 180, 'https://covers.openlibrary.org/b/isbn/9780143107712-L.jpg'),
    ('War and Peace', 'Leo Tolstoy', 'Historical Fiction', 1869, 'The lives of Russian aristocrats during the Napoleonic Wars.', 4.6, 330, 'https://covers.openlibrary.org/b/isbn/9781400079988-L.jpg'),
    ('Inferno', 'Dan Brown', 'Thriller', 2013, 'Langdon follows Dante’s clues through Florence.', 4.2, 190, 'https://covers.openlibrary.org/b/isbn/9780804172264-L.jpg'),
    ('The Lightning Thief', 'Rick Riordan', 'Fantasy', 2005, 'A modern-day boy discovers he is a demigod.', 4.4, 275, 'https://covers.openlibrary.org/b/isbn/9780786838653-L.jpg'),
    ('The Kite Runner', 'Khaled Hosseini', 'Historical Fiction', 2003, 'A story of friendship, betrayal, and redemption set in Afghanistan.', 4.6, 280, 'https://covers.openlibrary.org/b/isbn/9781594631931-L.jpg'),
    ('Animal Farm', 'George Orwell', 'Political Satire', 1945, 'A group of farm animals overthrow their human farmer and establish a society based on equality—only to find power corrupts.', 4.7, 370, 'https://covers.openlibrary.org/b/isbn/9780451526342-L.jpg');


INSERT INTO Ratings (username, bookname, stars) VALUES
('Ali', 'The Da Vinci Code', 5),
('Ahmed', 'The Time Machine', 4),
('Rayan', 'Pride and Prejudice', 5),
('Zoya', 'Gone Girl', 4),
('Fatima', 'Emma', 4),
('Bilal', 'Harry Potter and the Sorcerers Stone', 5),
('Usman', 'Sapiens', 5),
('Noor', 'The Lightning Thief', 5),
('Daniyal', 'War and Peace', 5),
('Areeba', 'The Great Gatsby', 4);

INSERT INTO Reviews (username, bookname, review) VALUES
('Ali', 'The Da Vinci Code', 'Thrilling and full of suspense.'),
('Ahmed', 'The Time Machine', 'Fascinating look at future.'),
('Rayan', 'Pride and Prejudice', 'A beautiful classic.'),
('Zoya', 'Gone Girl', 'Couldn’t put it down.'),
('Fatima', 'Emma', 'Charming and witty.'),
('Bilal', 'Harry Potter and the Sorcerers Stone', 'Magical!'),
('Usman', 'Sapiens', 'Mind-blowing insights.'),
('Noor', 'The Lightning Thief', 'Super fun!'),
('Areeba', 'The Great Gatsby', 'Great commentary on the Jazz Age.');




INSERT INTO Followers (follower, followee) VALUES
('Ali', 'Ahmed'),
('Ahmed', 'Rayan'),
('Rayan', 'Azlan'),
('Zoya', 'Fatima'),
('Noor', 'Bilal');

INSERT INTO Follows (follower, followee) VALUES
('Ali', 'Rayan'),
('Fatima', 'Zoya'),
('Bilal', 'Usman'),
('Areeba', 'Daniyal');


INSERT INTO ReadBooksList (username, bookname) VALUES
('Ali', 'The Da Vinci Code'),
('Ahmed', 'The Time Machine'),
('Fatima', 'Emma'),
('Bilal', 'Harry Potter and the Sorcerers Stone'),
('Usman', 'Sapiens');

INSERT INTO WishlistBooks (username, bookname) VALUES
('Zoya', 'The Girl on the Train'),
('Noor', 'The Hobbit'),
('Taha', 'The Little Prince');

INSERT INTO CurrentlyReadingBooks (username, bookname) VALUES
('Ahmed', '1984'),
('Rayan', 'Les Misérables'),
('Daniyal', 'Crime and Punishment');

INSERT INTO LikedBooksList (username, bookname) VALUES
('Ali', 'The Da Vinci Code'),
('Fatima', 'Pride and Prejudice'),
('Bilal', 'The Hobbit'),
('Noor', 'The Lightning Thief');


INSERT INTO UserGraph (username, bookname, ratingGiven) VALUES
('Sara', '1984', 5),
('Usman', 'The Great Gatsby', 3),
('Hina', 'Pride and Prejudice', 4),
('Bilal', 'To Kill a Mockingbird', 5),
('Nida', 'The Catcher in the Rye', 2),
('Tariq', 'The Hobbit', 4),
('Ayesha', 'Fahrenheit 451', 5),
('Hamza', 'Moby Dick', 3);

INSERT INTO BookGraph (bookname, username, ratingReceived) VALUES
('1984', 'Sara', 5),
('The Great Gatsby', 'Usman', 3),
('Pride and Prejudice', 'Hina', 4),
('To Kill a Mockingbird', 'Bilal', 5),
('The Catcher in the Rye', 'Nida', 2),
('The Hobbit', 'Tariq', 4),
('Fahrenheit 451', 'Ayesha', 5),
('Moby Dick', 'Hamza', 3);

INSERT INTO Notifications (notificationID, sendby, sendto, message) VALUES
(1, 'Ali', 'Fatima', 'Just finished The Time Machine. Highly recommend'),
(2, 'Fatima', 'Zoya', 'Crime and Punishment is an amazing book'),
(3, 'Rayan', 'Ahmed', 'Gone Girl. You should check it out');