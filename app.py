from flask import Flask, request, render_template, redirect
from werkzeug.security import generate_password_hash

app = Flask(__name__)
app.secret_key = "your_secret_key"

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

        return render_template("register.html", message="Registered successfully!", category="success")

    return render_template("register.html")


if __name__ == "__main__":
    app.run(debug=True)
