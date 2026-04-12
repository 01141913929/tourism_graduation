import firebase_admin
from firebase_admin import credentials, firestore
import urllib.request
from urllib.error import HTTPError

def check_url(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        urllib.request.urlopen(req)
        return True
    except HTTPError as e:
        if e.code == 404:
            return False
        return True # other errors we assume it might work
    except Exception:
        return False

# Some reliable fallback images for Egypt / Oriental / Souk
FALLBACKS = [
    "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800", # Khan el Khalili
    "https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800", # Bazaar
    "https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=800", # Sphinx
    "https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800", # Scarab
    "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800", # Textiles
    "https://images.unsplash.com/photo-1565118531796-763e5082d113?w=800", # Horus Statue
]

def main():
    if not firebase_admin._apps:
        cred = credentials.Certificate("service_account.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    
    collections_to_check = ['bazaars', 'products', 'artifacts']
    fixed_count = 0
    fallback_index = 0

    print("Checking database for 404 image URLs...")
    for col in collections_to_check:
        docs = db.collection(col).stream()
        for doc in docs:
            data = doc.to_dict()
            updates = {}
            
            # Check imageUrl
            if 'imageUrl' in data and data['imageUrl']:
                url = data['imageUrl']
                if "unsplash.com" in url and not check_url(url):
                    print(f"404 URL in {col}/{doc.id}: {url}")
                    new_url = FALLBACKS[fallback_index % len(FALLBACKS)]
                    fallback_index += 1
                    updates['imageUrl'] = new_url
            
            # Check galleryImages
            if 'galleryImages' in data and isinstance(data['galleryImages'], list):
                new_gallery = []
                changed = False
                for g_url in data['galleryImages']:
                    if "unsplash.com" in g_url and not check_url(g_url):
                        print(f"404 Gallery URL in {col}/{doc.id}: {g_url}")
                        new_g_url = FALLBACKS[fallback_index % len(FALLBACKS)]
                        fallback_index += 1
                        new_gallery.append(new_g_url)
                        changed = True
                    else:
                        new_gallery.append(g_url)
                if changed:
                    updates['galleryImages'] = new_gallery
            
            if updates:
                db.collection(col).document(doc.id).update(updates)
                fixed_count += 1
                print(f"Updated {doc.id} with {updates}")

    print(f"Done! Fixed {fixed_count} documents.")

if __name__ == "__main__":
    main()
