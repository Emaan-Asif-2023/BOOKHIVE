import sqlite3
from flask import Flask, request, render_template, redirect
from werkzeug.security import generate_password_hash, check_password_hash
from flask import session
from flask import url_for,  flash


app = Flask(__name__)
app.secret_key = "your_secret_key"

#login_manager = LoginManager()
#login_manager.init_app(app)
#login_manager.login_view = "login"

DATABASE = "dbprojectNew.db"

def get_db_connection():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with app.app_context():
        conn = get_db_connection()
        with open("schema.sql", "r") as f:
            conn.executescript(f.read())
        conn.close()

#Logo page


@app.route("/initdb")
def run_initdb():
    init_db()

    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()

    table_data = {}
    for table in tables:
        table_name = table['name']
        
        cursor.execute(f"SELECT * FROM {table_name};")
        data = cursor.fetchall()
        table_data[table_name] = data
    
    conn.close()
    
    return render_template("initdb.html", table_data=table_data)

@app.route('/')
def splash():
     return render_template("logo.html")  #commenting out for while because the logo display takes time and we are in development

#@app.route("/")
#def home():
#    return redirect("/register")

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        email = request.form.get("email")

        if not (username and password and email):
            return render_template("register.html", message="All fields are required.", category="error")

        hashed_password = generate_password_hash(password)

        # Simulate saving to database
        # TODO: Your DB code here
        conn = get_db_connection()
        try:
            conn.execute(
                "INSERT INTO Users (username, email, password) VALUES (?, ?, ?)",
                (username, email, hashed_password)
            )
            conn.commit()

            session["username"] = username
        except sqlite3.IntegrityError:
            return render_template("register.html", message="Username or email already exists.", category="error")
        finally:
            conn.close()

        return redirect("/home")
        
        return render_template("register.html", message="Registered successfully!", category="success") #won't run because need to redirect

    return render_template("register.html")

@app.route("/login", methods=["GET", "POST"]) #write backend for login
def login():
    if request.method == "POST":
        username = request.form.get("username")
        email = request.form.get("email")
        password = request.form.get("password")

        conn = get_db_connection()
        user = conn.execute("SELECT * FROM Users WHERE username = ? AND email = ?", (username, email)).fetchone()
        conn.close()

        if user and user["password"] == password:
            session["username"] = user["username"]
            return redirect("/home")

        elif user and check_password_hash(user["password"], password):
            session["username"] = user["username"]
            return redirect("/home")

        else:
            return render_template("login.html", message="Invalid credentials", category="error")

    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/register")


@app.route("/home", methods=["GET", "POST"])
def homepage():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == "POST":
        query = request.form.get("search", "").lower()
        sql_query = """
            SELECT bookname, author, genre,
                   COALESCE(cover_url, '/static/default-cover.jpg') AS safe_cover
            FROM Books
            WHERE LOWER(bookname) LIKE ?
               OR LOWER(author) LIKE ?
               OR LOWER(genre) LIKE ?
        """
        wildcard = f"%{query}%"
        cur.execute(sql_query, (wildcard, wildcard, wildcard))
        books = cur.fetchall()
    else:
        books = cur.execute("""
            SELECT bookname, author, genre,
                   COALESCE(cover_url, '/static/default-cover.jpg') AS safe_cover
            FROM Books
        """).fetchall()

    conn.close()
    return render_template("home.html", books=books)



@app.route("/search", methods=["GET", "POST"])
def search_users():
    if "username" not in session:
        return redirect("/login")

    current_user = session["username"]
    conn = get_db_connection()

    if request.method == "POST":
        search_term = request.form.get("search_term")
        users = conn.execute(
            "SELECT * FROM Users WHERE username LIKE ? OR email LIKE ?",
            (f"%{search_term}%", f"%{search_term}%")
        ).fetchall()
    else:
        users = conn.execute("SELECT * FROM Users").fetchall()

    followed = conn.execute("SELECT followee FROM Follows WHERE follower = ?", (current_user,)).fetchall()
    followed_set = {row['followee'] for row in followed}

    conn.close()
    return render_template("search_users.html", users=users, followed_set=followed_set, current_user=current_user)


@app.route("/allusers")
def all_users():
    if "username" not in session:
        return redirect("/login")

    current_user = session["username"]

    conn = get_db_connection()

    users = conn.execute("SELECT * FROM Users").fetchall()

    followed = conn.execute("SELECT followee FROM Follows WHERE follower = ?", (current_user,)).fetchall()
    followed_set = {row['followee'] for row in followed}

    conn.close()

    return render_template("allusers.html", users=users, followed_set=followed_set, current_user=current_user)


@app.route("/edit_cover/<bookname>", methods=["GET", "POST"])
def edit_cover(bookname):
    if request.method == "POST":
        new_url = request.form["cover_url"]
        conn = get_db_connection()
        conn.execute(
            "UPDATE Books SET cover_url = ? WHERE bookname = ?",
            (new_url, bookname)
        )
        conn.commit()
        conn.close()
        return redirect("/home")


    return render_template("edit_cover.html", bookname=bookname)

    
    #return render_template("edit_cover.html", bookname=bookname)
@app.route('/book/<bookname>')
def show_book(bookname):
    if "username" not in session:
        return redirect("/login")

    current_user = session["username"]
    conn = get_db_connection()

    users = conn.execute("SELECT username FROM Users WHERE username != ?", (current_user,)).fetchall()

    book = conn.execute("SELECT * FROM Books WHERE bookname = ?", (bookname,)).fetchone()
    if not book:
        conn.close()
        return "Book not found", 404

    # Get current user's rating for this book
    rating = conn.execute("SELECT stars FROM Ratings WHERE username = ? AND bookname = ?", (current_user, bookname)).fetchone()
    user_rating = rating["stars"] if rating else 0

    conn.close()

    return render_template("bookpage.html", book=book, user_rating=user_rating)

@app.route("/reading_lists", methods=["GET", "POST"])
def reading_lists():
    if "username" not in session:
        return redirect("/login")

    username = session["username"]
    conn = get_db_connection()

    # Fetch books for each list
    read = conn.execute(
        "SELECT B.bookname FROM ReadBooksList R JOIN Books B ON R.bookname = B.bookname WHERE R.username = ?",
        (username,)
    ).fetchall()

    reading = conn.execute(
        "SELECT B.bookname FROM CurrentlyReadingBooks C JOIN Books B ON C.bookname = B.bookname WHERE C.username = ?",
        (username,)
    ).fetchall()

    wishlist = conn.execute(
        "SELECT B.bookname FROM WishlistBooks W JOIN Books B ON W.bookname = B.bookname WHERE W.username = ?",
        (username,)
    ).fetchall()

    conn.close()

    return render_template("reading_lists.html", read=read, reading=reading, wishlist=wishlist)

@app.route("/add_to_list", methods=["POST"])
def add_to_list():
    if "username" not in session:
        return redirect("/login")

    username = session["username"]
    bookname = request.form.get("bookname")
    list_type = request.form.get("list_type")

    # Table map for lists
    table_map = {
        "read": "ReadBooksList",
        "reading": "CurrentlyReadingBooks",
        "wishlist": "WishlistBooks"
    }

    if list_type not in table_map:
        return "Invalid list type", 400

    # Check if the book exists in the Books table
    conn = get_db_connection()
    book_exists = conn.execute(
        "SELECT 1 FROM Books WHERE bookname = ? LIMIT 1", (bookname,)
    ).fetchone()

    # If book doesn't exist, fetch the lists and return an error message
    if not book_exists:
        # Fetch books for each list to pass them to the template
        read = conn.execute(
            "SELECT B.bookname FROM ReadBooksList R JOIN Books B ON R.bookname = B.bookname WHERE R.username = ?",
            (username,)
        ).fetchall()

        reading = conn.execute(
            "SELECT B.bookname FROM CurrentlyReadingBooks C JOIN Books B ON C.bookname = B.bookname WHERE C.username = ?",
            (username,)
        ).fetchall()

        wishlist = conn.execute(
            "SELECT B.bookname FROM WishlistBooks W JOIN Books B ON W.bookname = B.bookname WHERE W.username = ?",
            (username,)
        ).fetchall()

        conn.close()
        return render_template("reading_lists.html", 
                               read=read, reading=reading, wishlist=wishlist,
                               message="Book not found.", category="error")

    # If book exists, insert into the appropriate list
    target_table = table_map[list_type]

    try:
        conn.execute(
            f"INSERT OR IGNORE INTO {target_table} (username, bookname) VALUES (?, ?)",
            (username, bookname)
        )
        conn.commit()
    except Exception as e:
        conn.close()
        return f"Error: {e}", 500

    conn.close()

    # Redirect back to the reading lists page after adding the book
    return redirect("/reading_lists")

@app.route("/remove_from_list", methods=["POST"])
def remove_from_list():
    if "username" not in session:
        return redirect("/login")

    username = session["username"]
    bookname = request.form.get("bookname")
    list_type = request.form.get("list_type")

    table_map = {
        "read": "ReadBooksList",
        "reading": "CurrentlyReadingBooks",
        "wishlist": "WishlistBooks"
    }

    if list_type not in table_map:
        return "Invalid list type", 400

    conn = get_db_connection()
    try:
        conn.execute(
            f"DELETE FROM {table_map[list_type]} WHERE username = ? AND bookname = ?",
            (username, bookname)
        )
        conn.commit()
    except Exception as e:
        return f"Error: {e}", 500
    finally:
        conn.close()

    return redirect("/reading_lists")

@app.route("/catalogue")
def catalogue():
    conn = get_db_connection()
    genre = request.args.get("genre")
    author = request.args.get("author")
    sort_by = request.args.get("sort_by")  # e.g., rating, name

    query = "SELECT * FROM Books"
    filters = []
    values = []

    #if genre: # exact matching
        #filters.append("genre = ?")
        #values.append(genre)
    if genre: #partial matching
        filters.append("genre LIKE ?")
        values.append(f"%{genre}%")

    #if author: #exact matching for author
     #   filters.append("author = ?")
      #  values.append(author)
    if author: #partial matching
        filters.append("author LIKE ?")
        values.append(f"%{author}%")

    if filters:
        query += " WHERE " + " AND ".join(filters)

    if sort_by == "rating":
        query += " ORDER BY averageRating DESC"
    elif sort_by == "name":
        query += " ORDER BY bookname ASC"

    books = conn.execute(query, values).fetchall()
    conn.close()

    return render_template("catalogue.html", books=books)

@app.route('/rate', methods=['POST'])
def rate():
    user_id = session['user_id']
    book_id = request.form['book_id']
    rating = int(request.form['rating'])

    conn = sqlite3.connect('yourdb.db')
    cursor = conn.cursor()
    cursor.execute('INSERT INTO ratings (user_id, book_id, rating) VALUES (?, ?, ?)', (user_id, book_id, rating))
    conn.commit()
    conn.close()

    return redirect('/home')

@app.route('/recommendations')
def recommendations():
    if 'username' not in session:
        return redirect('/login')

    user_id = session['username']
    #conn = sqlite3.connect('yourdb.db')  # Simplified path
    conn = get_db_connection()
    cursor = conn.cursor()

    try:

        cursor.execute('''
            SELECT b.genre, AVG(r.stars) as avg_rating
            FROM Ratings r
            JOIN Books b ON r.bookname = b.bookname
            WHERE r.username = ?
            GROUP BY b.genre
            ORDER BY avg_rating DESC
            LIMIT 1
        ''', (user_id,))
        top_genre = cursor.fetchone()

        recommendations = []
        if top_genre:
            genre = top_genre[0]

            cursor.execute('''
                SELECT b.* 
                FROM Books b
                WHERE b.genre = ? 
                AND b.bookname NOT IN (
                    SELECT r.bookname 
                    FROM Ratings r 
                    WHERE r.username = ?
                )
                ORDER BY b.averageRating DESC
                LIMIT 5
            ''', (genre, user_id))
            recommendations = cursor.fetchall()

        return render_template('recommendations.html', books=recommendations)

    #except sqlite3.Error as e:
     #   print(f"Database error: {e}")
      #  return "Error generating recommendations", 500
    except sqlite3.Error as e:
        return render_template('recommendations.html', books=[], error=f"Database error: {e}")
        
    finally:
        conn.close()





@app.route('/profile')
def profile():
    if 'username' not in session:
        return redirect(url_for('login'))
    
    username = session['username']
    
    try:
        conn = get_db_connection()
        
        # Get user info
        user = conn.execute('SELECT * FROM Users WHERE username = ?', (username,)).fetchone()
        if not user:
            return redirect(url_for('login'))
        
        # Get user stats
        books_read = conn.execute('SELECT COUNT(*) FROM ReadBooksList WHERE username = ?', (username,)).fetchone()[0]
        wishlist_count = conn.execute('SELECT COUNT(*) FROM WishlistBooks WHERE username = ?', (username,)).fetchone()[0]
        currently_reading = conn.execute('SELECT COUNT(*) FROM CurrentlyReadingBooks WHERE username = ?', (username,)).fetchone()[0]
        
        # Get recent reviews
        reviews = conn.execute('''
            SELECT b.bookname, b.author, r.review 
            FROM Reviews r
            JOIN Books b ON r.bookname = b.bookname
            WHERE r.username = ?
            ORDER BY r.rowid DESC
            LIMIT 3
        ''', (username,)).fetchall()
        
        # Get followers/following count
        followers = conn.execute('SELECT COUNT(*) FROM Followers WHERE followee = ?', (username,)).fetchone()[0]
        following = conn.execute('SELECT COUNT(*) FROM Followers WHERE follower = ?', (username,)).fetchone()[0]
        
        conn.close()
        
        return render_template('profile.html',
        username=user['username'],
        email=user['email'],
        description=user['description'],
        books_read=books_read,
        wishlist_count=wishlist_count,
        currently_reading=currently_reading,
        reviews=reviews,
        followers=followers,
        following=following)
    
    except sqlite3.Error as e:
        print(f"Database error: {e}")
        return "Error loading profile", 500
    
@app.route("/profile_editing", methods=["GET", "POST"])
def profile_editing():
    if "username" not in session:
        return redirect("/login")

    old_username = session["username"]
    conn = get_db_connection()

    if request.method == "POST":
        new_username = request.form.get("username")
        new_password = request.form.get("password")
        new_description = request.form.get("description")

        if not new_username:
            user = conn.execute("SELECT * FROM Users WHERE username = ?", (old_username,)).fetchone()
            conn.close()
            return render_template("profile_editing.html", user=user, message="Username cannot be empty.", category="error")

        try:
            conn.execute(
                "UPDATE Users SET username = ?, password = ?, description = ? WHERE username = ?",
                (new_username, new_password, new_description, old_username)
            )
            conn.commit()
            session["username"] = new_username
            message = "Profile updated successfully!"
        except sqlite3.IntegrityError:
            message = "Username already taken."
            new_username = old_username  # rollback change on error
        finally:
            user = conn.execute("SELECT * FROM Users WHERE username = ?", (new_username,)).fetchone()
            conn.close()

        return render_template("profile_editing.html", user=user, message=message, category="success")

    # For GET request
    user = conn.execute("SELECT * FROM Users WHERE username = ?", (old_username,)).fetchone()
    conn.close()
    return render_template("profile_editing.html", user=user)

@ app.route("/follow/<username>", methods=["POST"])

def follow(username):
    if "username" not in session or session["username"] == username:
        return redirect("/search")

    conn = get_db_connection()
    conn.execute("INSERT OR IGNORE INTO Follows (follower, followee) VALUES (?, ?)",
                     (session["username"], username))
    conn.commit()
    conn.close()
    return redirect("/search")

@app.route("/unfollow/<username>", methods=["POST"])
def unfollow(username):
    if "username" not in session or session["username"] == username:
        return redirect("/search")

    conn = get_db_connection()
    conn.execute("DELETE FROM Follows WHERE follower = ? AND followee = ?",
                     (session["username"], username))
    conn.commit()
    conn.close()
    return redirect("/search")


#@app.route("/follow/<followed_username>", methods=["POST"])
#def follow_user(followed_username):
 #   if "username" not in session:
  #      return redirect("/login")

   # current_user = session["username"]
    conn = get_db_connection()

    #if current_user == followed_username:
     #   return "Cannot follow yourself.", 400

    #try:
     #   conn.execute(
      #      "INSERT OR IGNORE INTO Followers (follower, followed) VALUES (?, ?)",
       #     (current_user, followed_username)
        #)
        #conn.commit()
    #except Exception as e:
     #   conn.close()
      #  return f"Error: {e}", 500

    #conn.close()
    #return redirect("/allusers")

#view profile
@app.route('/profile/<username>')
def view_profile(username):
    if 'username' not in session:
        return redirect(url_for('login'))

    current_user = session['username']

    try:
        conn = get_db_connection()

        profile_user = conn.execute('SELECT * FROM Users WHERE username = ?', (username,)).fetchone()
        if not profile_user:
            conn.close()
            return "User not found", 404

        books_read = conn.execute('SELECT COUNT(*) FROM ReadBooksList WHERE username = ?', (username,)).fetchone()[0]
        wishlist_count = conn.execute('SELECT COUNT(*) FROM WishlistBooks WHERE username = ?', (username,)).fetchone()[0]
        currently_reading = conn.execute('SELECT COUNT(*) FROM CurrentlyReadingBooks WHERE username = ?', (username,)).fetchone()[0]


        reviews = conn.execute('''
            SELECT b.bookname, b.author, r.review 
            FROM Reviews r
            JOIN Books b ON r.bookname = b.bookname
            WHERE r.username = ?
            ORDER BY r.rowid DESC
            LIMIT 3
        ''', (username,)).fetchall()

        followers = conn.execute('SELECT COUNT(*) FROM Followers WHERE followee = ?', (username,)).fetchone()[0]
        following = conn.execute('SELECT COUNT(*) FROM Followers WHERE follower = ?', (username,)).fetchone()[0]

        is_following = conn.execute(
            'SELECT 1 FROM Followers WHERE follower = ? AND followee = ?',
            (current_user, username)
        ).fetchone()

        conn.close()
        template_to_render = 'profile.html' if current_user == username else 'profile_user.html'
        return render_template(template_to_render,
            username=profile_user['username'],
            email=profile_user['email'],
            description=profile_user['description'],
            books_read=books_read,
            wishlist_count=wishlist_count,
            currently_reading=currently_reading,
            reviews=reviews,
            followers=followers,
            following=following,
            is_following=is_following,
            #is_friend=None
        )

    except sqlite3.Error as e:
        print(f"Database error: {e}")
        return "Error loading profile", 500

@app.route("/chat", methods=["GET", "POST"])
def chat():
    if "username" not in session:
        return redirect("/login")

    current_user = session["username"]
    conn = get_db_connection()
    users = conn.execute("SELECT username FROM Users WHERE username != ?", (current_user,)).fetchall()

    success = None
    error = None

    if request.method == "POST":
        recipient = request.form.get("sendto")
        message = request.form.get("message")

        if not recipient or not message:
            conn.close()
            return render_template("chat.html", current_user=current_user, error="Recipient and message are required.", users=users)

        try:
            conn.execute(
                "INSERT INTO Notifications (sendby, sendto, message) VALUES (?, ?, ?)",
                (current_user, recipient, message)
            )
            conn.commit()
            success = "Message sent successfully!"
        except sqlite3.Error as e:
            conn.close()
            return f"Database error: {e}", 500

    chats = []
    conn.close()

    return render_template("chat.html", chats=chats, current_user=current_user, users=users, success=success, error=error)


@app.route("/notifications")
def notifications():
    if "username" not in session:
        return redirect("/login")

    current_user = session["username"]
    conn = get_db_connection()

    users = conn.execute("SELECT username FROM Users WHERE username != ?", (current_user,)).fetchall()

    notifications = conn.execute('''
        SELECT sendby, message 
        FROM Notifications 
        WHERE sendto = ?
        ORDER BY rowid DESC
    ''', (current_user,)).fetchall()

    conn.close()

    return render_template("notifications.html", notifications=notifications, current_user=current_user)

@app.route('/top_picks/<username>')
def view_top_picks(username):
    current_user = session.get('username')
    conn = get_db_connection()
    user = conn.execute('SELECT topPick1, topPick2, topPick3 FROM Users WHERE username = ?', (username,)).fetchone()
    conn.close()

    if not user:
        return "User not found", 404

    template = 'top_picks.html' if username == current_user else 'top_picks_user.html'
    return render_template(template, username=username, owner=username, user=user)


@app.route('/top_picks')
def top_picks():
    username = session.get('username')
    conn = get_db_connection()
    user = conn.execute('SELECT topPick1, topPick2, topPick3 FROM Users WHERE username = ?', (username,)).fetchone()
    conn.close()
    return render_template('top_picks.html', user=user)

@app.route('/update_top_picks', methods=['POST'])
def update_top_picks():
    username = session.get('username')
    pick1 = request.form.get('topPick1')
    pick2 = request.form.get('topPick2')
    pick3 = request.form.get('topPick3')

    conn = get_db_connection()
    conn.execute('UPDATE Users SET topPick1 = ?, topPick2 = ?, topPick3 = ? WHERE username = ?', (pick1, pick2, pick3, username))
    conn.commit()
    conn.close()
    return redirect('/top_picks')

@app.route('/delete_top_pick/<int:pick_number>', methods=['POST'])
def delete_top_pick(pick_number):
    username = session.get('username')
    column = f"topPick{pick_number}"
    conn = get_db_connection()
    conn.execute(f'UPDATE Users SET {column} = NULL WHERE username = ?', (username,))
    conn.commit()
    conn.close()
    return redirect('/top_picks')

@app.route('/view_ratings/<bookname>')
def view_ratings(bookname):
    conn = get_db_connection()
    ratings = conn.execute(
        "SELECT username, stars FROM Ratings WHERE bookname = ?",
        (bookname,)
    ).fetchall()
    conn.close()

    usernames = [row["username"] for row in ratings]
    rating_values = [row["stars"] for row in ratings]


    return render_template("view_rating.html", usernames=usernames, ratings=rating_values, bookname=bookname)





@app.route('/rate_book/<bookname>', methods=['POST'])
def rate_book(bookname):
    username = session.get("username")
    stars = int(request.form["stars"])

    conn = get_db_connection()

    existing = conn.execute("SELECT * FROM Ratings WHERE username = ? AND bookname = ?",
                            (username, bookname)).fetchone()

    if existing:
        conn.execute("UPDATE Ratings SET stars = ? WHERE username = ? AND bookname = ?", (stars, username, bookname))
    else:
        conn.execute("INSERT INTO Ratings (username, bookname, stars) VALUES (?, ?, ?)", (username, bookname, stars))
        conn.execute("INSERT INTO BookGraph (bookname, username, ratingReceived) VALUES (?, ?, ?)",
                     (bookname, username, stars))
        conn.execute("INSERT INTO UserGraph (username, bookname, ratingGiven) VALUES (?, ?, ?)",
                     (username, bookname, stars))

    rating_data = conn.execute("SELECT AVG(stars) as avg, COUNT(*) as count FROM Ratings WHERE bookname = ?",
                               (bookname,)).fetchone()
    conn.execute("UPDATE Books SET averageRating = ?, noOfRatings = ? WHERE bookname = ?",
                 (rating_data["avg"], rating_data["count"], bookname))

    conn.commit()
    conn.close()

    flash("Your rating has been submitted!")
    return redirect(url_for("book_page", bookname=bookname))

@app.route('/search_books', methods=['GET', 'POST'])
def search_books():
    results = []
    if request.method == 'POST':
        query = request.form.get('query')
        conn = get_db_connection()
        cur = conn.cursor()

        sql_query = """
        SELECT * FROM Books
        WHERE lower(bookname) LIKE ?
        OR lower(author) LIKE ?
        OR lower(genre) LIKE ?
        """

        search_term = f"%{query.lower()}%"
        cur.execute(sql_query, (search_term, search_term, search_term))
        results = cur.fetchall()
        conn.close()

    return render_template('searchbook.html', results=results)

@app.route('/star_rating', methods=['POST'])
def star_rating():
    if "username" not in session:
        return {"status": "error", "message": "Login required"}, 401

    current_user = session["username"]
    data = request.get_json()
    bookname = data.get("bookname")
    stars = data.get("stars")

    if not bookname or not stars or not (1 <= stars <= 5):
        return {"status": "error", "message": "Invalid data"}, 400

    try:
        conn = get_db_connection()
        existing = conn.execute(
            "SELECT * FROM Ratings WHERE username = ? AND bookname = ?",
            (current_user, bookname)
        ).fetchone()

        if existing:
            conn.execute("UPDATE Ratings SET stars = ? WHERE username = ? AND bookname = ?",
                         (stars, current_user, bookname))
        else:
            conn.execute("INSERT INTO Ratings (username, bookname, stars) VALUES (?, ?, ?)",
                         (current_user, bookname, stars))

        # Optional: Update Books table's average and count
        rating_data = conn.execute("SELECT AVG(stars) as avg, COUNT(*) as count FROM Ratings WHERE bookname = ?",(bookname,)).fetchone()
        conn.execute("UPDATE Books SET averageRating = ?, noOfRatings = ? WHERE bookname = ?",
                     (rating_data["avg"], rating_data["count"], bookname))

        conn.commit()
        conn.close()

        return {"status": "success", "message": "Rating saved"}
    
    except Exception as e:
        print(f"Error in /star_rating: {e}")
        return {"status": "error", "message": "Server error"}, 500

if __name__ == "__main__":
    app.run(debug=True)