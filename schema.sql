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
('Animal Farm', 'George Orwell', 'Political Satire', 1945, 'A group of farm animals overthrow their human farmer and establish a society based on equality—only to find power corrupts.', 4.7, 370, 'https://covers.openlibrary.org/b/isbn/9780451526342-L.jpg'),
('A Tale of Two Cities', 'Charles Dickens', 'Historical Fiction', 1859, 'A story set before and during the French Revolution.', 4.5, 310, 'https://covers.openlibrary.org/b/isbn/9780141439600-L.jpg'),
('The Republic', 'Plato', 'Political Philosophy', -380, 'A Socratic dialogue on justice and the ideal state.', 4.6, 150, 'https://covers.openlibrary.org/b/isbn/9780140455113-L.jpg'),
('The Book Thief', 'Markus Zusak', 'Historical Fiction', 2005, 'A girl steals books in Nazi Germany, narrated by Death.', 4.6, 290, 'https://covers.openlibrary.org/b/isbn/9780375842207-L.jpg'),
('The Brothers Karamazov', 'Fyodor Dostoevsky', 'Philosophical Fiction', 1880, 'A story of faith, doubt, and patricide.', 4.9, 250, 'https://covers.openlibrary.org/b/isbn/9780374528379-L.jpg'),
('Frankenstein', 'Mary Shelley', 'Gothic Fiction', 1818, 'A scientist creates life and faces the consequences.', 4.3, 230, 'https://covers.openlibrary.org/b/isbn/9780486282114-L.jpg'),
('The Communist Manifesto', 'Karl Marx and Friedrich Engels', 'Political', 1848, 'A call to arms for the working class.', 4.4, 200, 'https://covers.openlibrary.org/b/isbn/9780140447576-L.jpg'),
('Midnight’s Children', 'Salman Rushdie', 'Historical Fiction', 1981, 'A boy born at the moment of India’s independence finds he is linked to other children with special powers.', 4.3, 180, 'https://covers.openlibrary.org/b/isbn/9780099511892-L.jpg'),
('The Catcher in the Rye', 'J.D. Salinger', 'Fiction', 1951, 'A teenager wanders New York in search of meaning.', 4.1, 300, 'https://covers.openlibrary.org/b/isbn/9780316769488-L.jpg'),
('Dracula', 'Bram Stoker', 'Horror', 1897, 'A vampire from Transylvania terrorizes London.', 4.4, 190, 'https://covers.openlibrary.org/b/isbn/9780486411095-L.jpg'),
('Beloved', 'Toni Morrison', 'Historical Fiction', 1987, 'A woman haunted by her past as a slave.', 4.6, 210, 'https://covers.openlibrary.org/b/isbn/9781400033416-L.jpg'),
('Things Fall Apart', 'Chinua Achebe', 'Political Fiction', 1958, 'The clash of African traditions and colonialism.', 4.5, 240, 'https://covers.openlibrary.org/b/isbn/9780385474542-L.jpg'),
('Harry Potter and the Chamber of Secrets', 'J.K. Rowling', 'Fantasy', 1998, 'Harry returns to Hogwarts and discovers a hidden chamber and a deadly secret.', 4.8, 480, 'https://covers.openlibrary.org/b/isbn/9780439064873-L.jpg'),
('Harry Potter and the Prisoner of Azkaban', 'J.K. Rowling', 'Fantasy', 1999, 'Harry learns about Sirius Black and the truth about his parents past.', 4.9, 470, 'https://covers.openlibrary.org/b/isbn/9780439136365-L.jpg'),
('Harry Potter and the Goblet of Fire', 'J.K. Rowling', 'Fantasy', 2000, 'Harry competes in a dangerous magical tournament.', 4.9, 460, 'https://covers.openlibrary.org/b/isbn/9780439139601-L.jpg'),
('Harry Potter and the Order of the Phoenix', 'J.K. Rowling', 'Fantasy', 2003, 'Harry faces the Ministry of Magic and builds Dumbledores Army.', 4.7, 450, 'https://covers.openlibrary.org/b/isbn/9780439358071-L.jpg'),
('Harry Potter and the Half-Blood Prince', 'J.K. Rowling', 'Fantasy', 2005, 'Harry uncovers secrets about Voldemort’s past.', 4.8, 440, 'https://covers.openlibrary.org/b/isbn/9780439785969-L.jpg'),
('Harry Potter and the Deathly Hallows', 'J.K. Rowling', 'Fantasy', 2007, 'Harry, Ron, and Hermione hunt for Horcruxes to defeat Voldemort.', 4.9, 500, 'https://covers.openlibrary.org/b/isbn/9780545010221-L.jpg'),
('The Fellowship of the Ring', 'J.R.R. Tolkien', 'Fantasy', 1954, 'A group sets out to destroy the One Ring and defeat Sauron.', 4.9, 450, 'https://covers.openlibrary.org/b/isbn/9780261103573-L.jpg'),
('The Two Towers', 'J.R.R. Tolkien', 'Fantasy', 1954, 'The fellowship is divided, and battles rage across Middle-earth.', 4.8, 440, 'https://covers.openlibrary.org/b/isbn/9780261102361-L.jpg'),
('The Return of the King', 'J.R.R. Tolkien', 'Fantasy', 1955, 'The final battle for Middle-earth and the destruction of the Ring.', 4.9, 460, 'https://covers.openlibrary.org/b/isbn/9780261102378-L.jpg'),
('A Study in Scarlet', 'Arthur Conan Doyle', 'Mystery', 1887, 'The first Sherlock Holmes mystery, introducing Holmes and Watson.', 4.7, 310, 'https://covers.openlibrary.org/b/isbn/9780140439083-L.jpg'),
('The Sign of the Four', 'Arthur Conan Doyle', 'Mystery', 1890, 'Holmes investigates a stolen treasure and a mysterious pact.', 4.6, 300, 'https://covers.openlibrary.org/b/isbn/9780140439076-L.jpg'),
('The Adventures of Sherlock Holmes', 'Arthur Conan Doyle', 'Mystery', 1892, 'A collection of Holmes’s most famous cases.', 4.8, 350, ''),
('The Hound of the Baskervilles', 'Arthur Conan Doyle', 'Mystery', 1902, 'Holmes investigates a legendary hound haunting the moors.', 4.9, 370, 'https://covers.openlibrary.org/b/isbn/9780141034324-L.jpg'),
('The Lion, the Witch and the Wardrobe', 'C.S. Lewis', 'Fantasy', 1950, 'Four children discover a magical world ruled by an evil witch.', 4.8, 400, 'https://covers.openlibrary.org/b/isbn/9780064471046-L.jpg'),
('Prince Caspian', 'C.S. Lewis', 'Fantasy', 1951, 'The Pevensie children return to help Prince Caspian reclaim his throne.', 4.5, 380, 'https://covers.openlibrary.org/b/isbn/9780064471053-L.jpg'),
('The Voyage of the Dawn Treader', 'C.S. Lewis', 'Fantasy', 1952, 'A seafaring adventure in Narnia.', 4.6, 360, 'https://covers.openlibrary.org/b/isbn/9780064471077-L.jpg'),
('The Silver Chair', 'C.S. Lewis', 'Fantasy', 1953, 'A quest to find a missing prince in a dark, underground world.', 4.4, 340, 'https://covers.openlibrary.org/b/isbn/9780064471091-L.jpg'),
('The Horse and His Boy', 'C.S. Lewis', 'Fantasy', 1954, 'A boy and a talking horse escape slavery in Calormen.', 4.3, 320, 'https://covers.openlibrary.org/b/isbn/9780064471060-L.jpg'),
('Dune', 'Frank Herbert', 'Science Fiction', 1965, 'Paul Atreides leads a rebellion on the desert planet Arrakis.', 4.6, 390, 'https://covers.openlibrary.org/b/isbn/9780441172719-L.jpg'),
('Dune Messiah', 'Frank Herbert', 'Science Fiction', 1969, 'Paul Atreides struggles with his role as Emperor and prophet.', 4.4, 320, 'https://covers.openlibrary.org/b/isbn/9780441172696-L.jpg'),
('Children of Dune', 'Frank Herbert', 'Science Fiction', 1976, 'Paul’s children face political and religious turmoil.', 4.3, 310, 'https://covers.openlibrary.org/b/isbn/9780441104024-L.jpg'),
('God Emperor of Dune', 'Frank Herbert', 'Science Fiction', 1981, 'Leto II rules the galaxy as a tyrant to ensure humanity’s survival.', 4.2, 280, ''),
('Heretics of Dune', 'Frank Herbert', 'Science Fiction', 1984, 'A new order arises in a galaxy reshaped by Leto II’s legacy.', 4.1, 260, 'https://covers.openlibrary.org/b/isbn/9780441328000-L.jpg'),
('The Giver', 'Lois Lowry', 'Dystopian', 1993, 'A boy discovers the truth behind his perfect world.', 4.6, 240, 'https://covers.openlibrary.org/b/isbn/0544336267-L.jpg'),
('Chapterhouse: Dune', 'Frank Herbert', 'Science Fiction', 1985, 'The Bene Gesserit face threats from within and beyond.', 4.0, 250, 'https://covers.openlibrary.org/b/isbn/9780441102679-L.jpg');


INSERT INTO Ratings (username, bookname, stars) VALUES
('Ali', 'The Time Machine', 4),
('Ahmed', 'Pride and Prejudice', 5),
('Bilal', 'The Da Vinci Code', 4),
('Usman', 'The Stranger', 5),
('Zoya', 'The Great Gatsby', 4),
('Noor', '1984', 5),
('Fatima', 'Crime and Punishment', 5),
('Areeba', 'Metamorphosis', 4),
('Taha', 'Harry Potter and the Sorcerers Stone', 5),
('Azlan', 'To Kill a Mockingbird', 4),
('Rayan', 'The Hobbit', 5),
('Ali', 'Gone Girl', 4),
('Ahmed', 'Sapiens', 4),
('Bilal', 'The Alchemist', 4),
('Usman', 'The Girl on the Train', 3),
('Zoya', 'The Little Prince', 5),
('Noor', 'Les Misérables', 5),
('Fatima', 'Charlotte’s Web', 4),
('Areeba', 'Emma', 4),
('Taha', 'War and Peace', 5),
('Azlan', 'Inferno', 3),
('Rayan', 'The Lightning Thief', 4),
('Ali', 'The Kite Runner', 5),
('Ahmed', 'Animal Farm', 4),
('Bilal', 'A Tale of Two Cities', 5),
('Usman', 'The Republic', 5),
('Zoya', 'The Book Thief', 4),
('Noor', 'The Brothers Karamazov', 5),
('Fatima', 'Frankenstein', 3),
('Areeba', 'The Communist Manifesto', 4),
('Taha', 'Midnight’s Children', 4),
('Azlan', 'The Catcher in the Rye', 4),
('Rayan', 'Dracula', 4),
('Ali', 'Beloved', 5),
('Ahmed', 'Things Fall Apart', 4),
('Bilal', 'Harry Potter and the Chamber of Secrets', 5),
('Usman', 'Harry Potter and the Prisoner of Azkaban', 5),
('Zoya', 'Harry Potter and the Goblet of Fire', 4),
('Noor', 'Harry Potter and the Order of the Phoenix', 5),
('Fatima', 'Harry Potter and the Half-Blood Prince', 4),
('Areeba', 'Harry Potter and the Deathly Hallows', 5),
('Taha', 'The Fellowship of the Ring', 5),
('Azlan', 'The Two Towers', 5),
('Rayan', 'The Return of the King', 5),
('Ali', 'A Study in Scarlet', 4),
('Ahmed', 'The Sign of the Four', 5),
('Bilal', 'The Adventures of Sherlock Holmes', 5),
('Usman', 'The Hound of the Baskervilles', 4),
('Zoya', 'The Lion, the Witch and the Wardrobe', 5);

INSERT INTO Reviews (username, bookname, review) VALUES
('Ali', 'The Da Vinci Code', 'Thrilling and full of suspense.'),
('Ahmed', 'The Time Machine', 'Fascinating look at future.'),
('Rayan', 'Pride and Prejudice', 'A beautiful classic.'),
('Zoya', 'Gone Girl', 'Couldn’t put it down.'),
('Noor', 'Gone Girl', 'Loved this'),
('Fatima', 'Emma', 'Charming and witty.'),
('Bilal', 'Harry Potter and the Sorcerers Stone', 'Magical!'),
('Usman', 'Sapiens', 'Mind-blowing insights.'),
('Taha', 'Sapiens', 'Amazing, so much to learn!'),
('Noor', 'The Lightning Thief', 'Super fun!'),
('Areeba', 'The Great Gatsby', 'Great commentary on the Jazz Age.'),
('Azlan', 'The Great Gatsby', 'Fabulous'),
('Ahmad', 'The Hobbit', 'A magical journey. Tolkien is a genius.'),
('Noor', 'Pride and Prejudice', 'Charming and full of wit!'),
('Bilal', 'Pride and Prejudice', 'Amazing book'),
('Ahmed', '1984', 'Very relevant even today.'),
('Ali', 'The Alchemist', 'Life-changing and poetic.'),
('Azlan', 'Gone Girl', 'Absolutely twisted. Loved it!'),
('Zoya', 'To Kill a Mockingbird', 'Powerful message and characters.'),
('Taha', 'The Giver', 'A thought-provoking dystopia.'),
('Ali', 'Sapiens', 'Brilliant take on human history.'),
('Rayan', 'Emma', 'Light-hearted and clever.'),
('Rayan', 'The Great Gatsby', 'Deep yet tragic.'),
('Areeba', 'The Little Prince', 'Profound and heartwarming.'),
('Areeba', 'Harry Potter and the Sorcerers Stone', 'Magical start to the series.'),
('Noor', 'War and Peace', 'Heavy but worth it.'),
('Zoya', 'The Girl on the Train', 'Kept me guessing till the end.'),
('Fatima', 'Eragon', 'Great for fantasy lovers.'),
('Fatima', 'Sharp Objects', 'Dark and gripping.'),
('Ahmed', 'Inferno', 'Classic Dan Brown puzzle-thriller.'),
('Usman', 'The Chronicles of Narnia', 'Whimsical and adventurous.'),
('Bilal', 'Sense and Sensibility', 'A heartfelt classic.'),
('Ali', 'Harry Potter and the Goblet of Fire', 'The tournament was thrilling!'),
('Usman', 'Harry Potter and the Goblet of Fire', 'My favourite of all');




INSERT INTO Followers (follower, followee) VALUES
('Ali', 'Rayan'),
('Ahmed', 'Azlan'),
('Rayan', 'Fatima'),
('Zoya', 'Noor'),
('Noor', 'Areeba'),
('Fatima', 'Bilal'),
('Bilal', 'Usman'),
('Areeba', 'Daniyal'),
('Daniyal', 'Ahmed'),
('Usman', 'Rayan'),
('Ali', 'Fatima'),
('Ahmed', 'Zoya'),
('Rayan', 'Noor'),
('Fatima', 'Ali'),
('Noor', 'Zoya'),
('Areeba', 'Fatima'),
('Daniyal', 'Ali'),
('Usman', 'Zoya'),
('Zoya', 'Bilal'),
('Noor', 'Ahmed'),
('Fatima', 'Rayan'),
('Ali', 'Zoya'),
('Ahmed', 'Areeba'),
('Rayan', 'Usman'),
('Bilal', 'Areeba');

INSERT INTO Follows (follower, followee) VALUES
('Ali', 'Rayan'),
('Ahmed', 'Fatima'),
('Rayan', 'Bilal'),
('Zoya', 'Ali'),
('Noor', 'Ahmed'),
('Fatima', 'Rayan'),
('Bilal', 'Ali'),
('Areeba', 'Zoya'),
('Daniyal', 'Fatima'),
('Usman', 'Ali'),
('Ali', 'Daniyal'),
('Ahmed', 'Noor'),
('Rayan', 'Zoya'),
('Fatima', 'Daniyal'),
('Noor', 'Areeba'),
('Zoya', 'Fatima'),
('Bilal', 'Noor'),
('Areeba', 'Rayan'),
('Daniyal', 'Ahmed'),
('Usman', 'Noor'),
('Ali', 'Usman'),
('Ahmed', 'Daniyal'),
('Rayan', 'Areeba'),
('Fatima', 'Zoya'),
('Bilal', 'Rayan');


INSERT INTO ReadBooksList (username, bookname) VALUES
('Ali', 'Pride and Prejudice'),
('Ahmed', 'The Stranger'),
('Rayan', 'To Kill a Mockingbird'),
('Azlan', '1984'),
('Fatima', '1984'),
('Zoya', 'The Girl on the Train'),
('Fatima', 'The Great Gatsby'),
('Noor', 'War and Peace'),
('Areeba', 'War and Peace'),
('Areeba', 'The Hobbit'),
('Usman', 'The Catcher in the Rye'),
('Zoya', 'Sapiens'),
('Bilal', 'The Lightning Thief'),
('Usman', 'The Lightning Thief');

INSERT INTO WishlistBooks (username, bookname) VALUES
('Ali', 'The Brothers Karamazov'),
('Ahmed', 'Beloved'),
('Rayan', 'Sapiens'),
('Zoya', 'Frankenstein'),
('Azlan', 'Dracula'),
('Usman', 'The Republic'),
('Bilal', 'The Book Thief'),
('Areeba', 'The Communist Manifesto'),
('Taha', 'The Lightning Thief'),
('Noor', 'The Time Machine');

INSERT INTO CurrentlyReadingBooks (username, bookname) VALUES
('Asim', 'The Catcher in the Rye'),
('Hassan', 'Les Misérables'),
('Rida', 'The Kite Runner'),
('Amir', 'The Fellowship of the Ring'),
('Nadia', 'Crime and Punishment'),
('Waleed', 'Charlotte’s Web'),
('Kashan', 'The Alchemist'),
('Usman', 'The Lightning Thief'),
('Sana', 'The Return of the King'),
('Nashit', 'The Girl on the Train');

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
(1, 'Ali', 'Zoya', 'Hey Zoya, have you read 1984? It’s intense!'),
(2,'Ahmed', 'Noor', 'I just finished The Da Vinci Code. Mind blown!'),
(3,'Zoya', 'Ali', 'Yes! 1984 is scary but so good.'),
(4, 'Areeba', 'Fatima', 'You must read The Great Gatsby! Classic vibes.'),
(5, 'Noor', 'Ahmed', 'Loved the twist in Gone Girl. So dark.'),
(6, 'Fatima', 'Rayan', 'Sapiens made me rethink history.'),
(7, 'Taha', 'Azlan', 'Crime and Punishment is deep. Read it!'),
(8, 'Azlan', 'Taha', 'Kafka’s Metamorphosis is weird but amazing.'),
(9, 'Rayan', 'Usman', 'To Kill a Mockingbird made me cry.'),
(10, 'Usman', 'Ali', 'Harry Potter will always be my childhood.'),
(11, 'Zoya', 'Areeba', 'Do you like thrillers? Try Inferno!'),
(12, 'Noor', 'Fatima', 'The Little Prince is such a beautiful read.'),
(13, 'Ahmed', 'Taha', 'Check out The Republic by Plato.'),
(14, 'Ali', 'Rayan', 'War and Peace is long but worth it.'),
(15, 'Areeba', 'Noor', 'Just started reading The Kite Runner.'),
(16, 'Fatima', 'Zoya', 'You might like The Girl on the Train.'),
(17, 'Taha', 'Usman', 'Animal Farm hits different with today’s politics.'),
(18, 'Azlan', 'Ali', 'The Book Thief is so poetic.'),
(19, 'Rayan', 'Ahmed', 'Midnight’s Children is magical realism done right.'),
(20, 'Usman', 'Fatima', 'Try The Hobbit! It’s adventurous.'),
(21, 'Ali', 'Taha', 'Loved Emma by Jane Austen.'),
(22, 'Noor', 'Azlan', 'Les Misérables was so emotional.'),
(23, 'Zoya', 'Rayan', 'Frankenstein isn’t what I expected.'),
(24, 'Ahmed', 'Areeba', 'The Stranger is so... unsettling.'),
(25, 'Areeba', 'Zoya', 'Have you read Beloved? It’s haunting.'),
(26, 'Fatima', 'Noor', 'Things Fall Apart made me think a lot.'),
(27, 'Taha', 'Ali', 'Dracula’s letters style was interesting.'),
(28, 'Azlan', 'Zoya', 'Do you like dystopias? Try 1984.'),
(29, 'Rayan', 'Ahmed', 'Let’s discuss Sapiens over coffee!'),
(30, 'Usman', 'Taha', 'Check out Dune series'),
(31, 'Ali', 'Fatima', 'The Time Machine made me question time travel.'),
(32, 'Noor', 'Usman', 'Jane Austen’s work never gets old.'),
(33, 'Zoya', 'Ahmed', 'Crime and Punishment deserves 5 stars.'),
(34, 'Ahmed', 'Fatima', 'The Alchemist is simple but powerful.'),
(35, 'Fatima', 'Zoya', 'Reading The Brothers Karamazov next!');