import sqlite3
from flask import Flask, request, render_template, redirect
from werkzeug.security import generate_password_hash

app = Flask(__name__)
app.secret_key = "your_secret_key"

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

@app.route("/initdb")
def initdb():
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

@app.route("/") #don't remove this single back slash it's needed to run
def home():
    return redirect("/register")  

@app.route("/login", methods=["GET", "POST"]) #write backend for login
def login():
    if request.method == "POST":
        
        pass
    return render_template("login.html")

@app.route("/home", methods=["GET", "POST"])
def homepage():
    conn = get_db_connection()
    
    # Handle POST requests (e.g., search/filter submissions)
    if request.method == "POST":
        search_query = request.form.get("search", "").strip()
        
        if search_query:
            books = conn.execute("""
                SELECT * FROM Books 
                WHERE bookname LIKE ? OR author LIKE ?
                ORDER BY bookname
            """, (f"%{search_query}%", f"%{search_query}%")).fetchall()
        else:
            books = conn.execute("SELECT * FROM Books").fetchall()
    # Handle GET requests (normal page load)
    else:
        books = conn.execute("""
            SELECT bookname, author, genre, 
                   COALESCE(cover_url, '/static/default-cover.jpg') AS safe_cover
            FROM Books
            ORDER BY bookname
        """).fetchall()
    
    conn.close()
    
    return render_template("home.html", books=books)

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

if __name__ == "__main__":
    app.run(debug=True)
