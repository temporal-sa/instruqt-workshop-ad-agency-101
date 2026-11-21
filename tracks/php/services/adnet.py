"""AdNet — the (fake) ad network behind CatNip Cola's campaign.

Run it:  .adnet-venv/bin/python services/adnet.py
         (listens on http://localhost:9999)

Chaos mode starts ON: PetTok's publish endpoint returns 503 until you
POST /chaos/off. Dogbook always returns 403 — CatNip Cola is banned there,
and no amount of retrying will fix that.
"""

from flask import Flask, jsonify, request

TRENDING = {
    "meowta": ["#CatNipColaSummer", "#MeowtaMoments"],
    "catstagram": ["#CatsOfCatstagram", "#SummerSplash"],
    "pettok": ["#PetTokFamous", "#CatNipChallenge"],
}
CHANNELS = set(TRENDING) | {"dogbook"}


def create_app() -> Flask:
    app = Flask("adnet")
    state = {"chaos": True}

    @app.get("/health")
    def health():
        return jsonify(status="ok", chaos=state["chaos"])

    @app.get("/chaos")
    def chaos_status():
        return jsonify(chaos=state["chaos"])

    @app.post("/chaos/<mode>")
    def chaos_toggle(mode: str):
        if mode not in ("on", "off"):
            return jsonify(error="use /chaos/on or /chaos/off"), 404
        state["chaos"] = mode == "on"
        print(f"*** CHAOS MODE: {mode.upper()} ***")
        return jsonify(chaos=state["chaos"])

    @app.get("/tagline")
    def tagline():
        brand = request.args.get("brand", "Your Brand")
        return jsonify(tagline=f"{brand}: Taste the Meow!")

    @app.get("/trending/<channel>")
    def trending(channel: str):
        if channel not in TRENDING:
            return jsonify(error="unknown channel"), 404
        return jsonify(channel=channel, hashtags=TRENDING[channel])

    @app.post("/validate-creative")
    def validate_creative():
        campaign = request.get_json(force=True)["campaign"]
        return jsonify(creative_id=f"creative-{campaign}", status="approved")

    @app.post("/reserve-budget")
    def reserve_budget():
        campaign = request.get_json(force=True)["campaign"]
        return jsonify(reservation_id=f"budget-{campaign}", amount=50000)

    @app.post("/publish/<channel>")
    def publish(channel: str):
        if channel not in CHANNELS:
            return jsonify(error="unknown channel"), 404
        if channel == "dogbook":
            return (
                jsonify(error="CatNip Cola is permanently banned on Dogbook (too much catnip)"),
                403,
            )
        if channel == "pettok" and state["chaos"]:
            return jsonify(error="PetTok ads API is on fire, try again shortly"), 503
        campaign = request.get_json(force=True)["campaign"]
        return jsonify(placement_id=f"{channel}-{campaign}", channel=channel)

    return app


if __name__ == "__main__":
    print("AdNet listening on http://localhost:9999 (chaos mode: ON)")
    create_app().run(host="0.0.0.0", port=9999)
