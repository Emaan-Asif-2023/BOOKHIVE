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