from lib.google_search_results import GoogleSearchResults

params = {
    "q" : " \"Facebook, Inc\" + \"ticker symbol\" ",
    "location" : "New York, New York, United States",
    "hl" : "en",
    "gl" : "us",
    "google_domain" : "google.com",
    "api_key" : "9b66566f114d4a876cb052f3ff8d5ef682bf76424fdab1928f45433f1cf5f06d",
    "output" : "html"
}

client = GoogleSearchResults(params)
results = client.get_dict()

print(results)
