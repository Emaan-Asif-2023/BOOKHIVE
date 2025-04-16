from flask import Flask, request, render_template, redirect, session
from werkzeug.security import generate_password_hash

app = Flask(__name__)
app.secret_key = "your_secret_key"

@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        # Validate form data
        username = request.form.get("username")
        password = request.form.get("password")
        email = request.form.get("email")

        if not (username and password and email):
            return render_template("register.html", message="All fields are required.")

        # Hash the password
        hashed_password = generate_password_hash(password)

        # Store user data in the database
        # Your database insertion code goes here

        return redirect("/login")

    return render_template("register.html")

if __name__ == "__main__":
    app.run(debug=True)