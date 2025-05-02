import sqlite3
from flask import Flask, request, render_template, redirect
from werkzeug.security import generate_password_hash
from flask import session

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
        else:
            return render_template("login.html", message="Invalid credentials", category="error")

    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/login")


@app.route("/home")
def homepage():
    conn = get_db_connection()
    
    # Safely get books even if cover_url column doesn't exist
    try:
        books = conn.execute("""
            SELECT bookname, author, genre,
                   COALESCE(cover_url, '/static/default-cover.jpg') AS safe_cover
            FROM Books
        """).fetchall()
    except sqlite3.OperationalError:  # If cover_url column is missing
        books = conn.execute("""
            SELECT bookname, author, genre,
                   '/static/default-cover.jpg' AS safe_cover
            FROM Books
        """).fetchall()
    
    conn.close()
    return render_template("home.html", books=books)


@app.route("/search", methods=["GET", "POST"])
def search():
    users = []
    if request.method == "POST":
        search_term = request.form.get("search_term")

        conn = get_db_connection()
        cursor = conn.execute(
            "SELECT username, email FROM Users WHERE username LIKE ? OR email LIKE ?",
            (f"%{search_term}%", f"%{search_term}%")
        )
        users = cursor.fetchall()
        conn.close()

    return render_template("search.html", users=users)

@app.route("/allusers")
def all_users():
    conn = get_db_connection()
    cursor = conn.execute("SELECT * FROM Users")
    users = cursor.fetchall()
    conn.close()
    return render_template("allusers.html", users=users)

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
    conn = get_db_connection()
    book = conn.execute('SELECT * FROM Books WHERE bookname = ?', (bookname,)).fetchone()
    conn.close()
    if book is None:
        return "Book not found", 404
    return render_template('bookpage.html', book=book)

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

if __name__ == "__main__":
    app.run(debug=True)