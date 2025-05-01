import sqlite3
from flask import Flask, request, render_template, redirect
from werkzeug.security import generate_password_hash

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
    return render_template("logo.html")


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

#@app.route("/") #don't remove this single back slash it's needed to run
#def home():
    #return redirect("/register")
    # commented this out as i felt this in unnecessary... / back alash will run
    #the logo then login or regitser page will appear..

@app.route("/login", methods=["GET", "POST"]) #write backend for login
def login():
    if request.method == "POST":
        
        pass
    return render_template("login.html")

@app.route("/home", methods=["GET", "POST"]) #write backend for home
def homepage():
    if request.method == "POST":
        
        pass
    return render_template("home.html")

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



if __name__ == "__main__":
    app.run(debug=True)
