from flask import Flask, render_template, request, jsonify
import json
import os
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

# Stories directory - persisted via K8s PVC
STORIES_DIR = "/app/stories"
os.makedirs(STORIES_DIR, exist_ok=True)


def generate_story_filename():
    """Generate a unique filename for each story submission."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
    return f"story_{timestamp}.json"


def save_story(form_data):
    """Save form submission as a JSON file."""
    try:
        filename = generate_story_filename()
        filepath = os.path.join(STORIES_DIR, filename)

        story_data = {
            "timestamp": datetime.now().isoformat(),
            "first_name": form_data.get("first_name", "").strip(),
            "last_name": form_data.get("last_name", "").strip(),
            "phone_number": form_data.get("phone_number", "").strip(),
            "email": form_data.get("email", "").strip(),
            "story_name": form_data.get("story_name", "").strip(),
            "story_about": form_data.get("story_about", "").strip(),
            "story_writing": form_data.get("story_writing", "").strip(),
        }

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(story_data, f, indent=2, ensure_ascii=False)

        return True, filename
    except Exception as e:
        return False, str(e)


def get_all_stories():
    """Retrieve all saved stories."""
    stories = []
    try:
        if os.path.exists(STORIES_DIR):
            for filename in sorted(os.listdir(STORIES_DIR), reverse=True):
                if filename.endswith(".json"):
                    filepath = os.path.join(STORIES_DIR, filename)
                    try:
                        with open(filepath, "r", encoding="utf-8") as f:
                            story_data = json.load(f)
                            story_data["file_name"] = filename
                            stories.append(story_data)
                    except Exception:
                        pass
    except Exception as e:
        print(f"Error reading stories: {e}")

    return stories


@app.route("/", methods=["GET"])
def index():
    """Render the story submission form."""
    stories = get_all_stories()
    return render_template("index.html", stories=stories)


@app.route("/submit", methods=["POST"])
def submit_story():
    """Handle form submission and save story."""
    try:
        form_data = request.form.to_dict()

        # Validate required fields
        required_fields = ["first_name", "last_name", "email", "story_name", "story_writing"]
        missing_fields = [field for field in required_fields if not form_data.get(field, "").strip()]

        if missing_fields:
            return jsonify({
                "success": False,
                "message": f"Missing required fields: {', '.join(missing_fields)}"
            }), 400

        # Save the story
        success, result = save_story(form_data)

        if success:
            return jsonify({
                "success": True,
                "message": "Story saved successfully!",
                "file_name": result
            }), 201
        else:
            return jsonify({
                "success": False,
                "message": f"Error saving story: {result}"
            }), 500

    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500


@app.route("/stories", methods=["GET"])
def get_stories():
    """API endpoint to retrieve all stories."""
    try:
        stories = get_all_stories()
        return jsonify({
            "success": True,
            "count": len(stories),
            "stories": stories
        }), 200
    except Exception as e:
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint for K8s liveness/readiness probes."""
    try:
        # Verify stories directory is accessible
        if os.path.exists(STORIES_DIR) and os.path.isdir(STORIES_DIR):
            return jsonify({"status": "healthy", "message": "App is running"}), 200
        else:
            return jsonify({"status": "unhealthy", "message": "Stories directory not accessible"}), 500
    except Exception as e:
        return jsonify({"status": "unhealthy", "message": str(e)}), 500


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
