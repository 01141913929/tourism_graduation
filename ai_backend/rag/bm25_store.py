"""
🔤 BM25 Store — فهرس بحث بالكلمات المفتاحية (محسّن للعربية)
بيدعم Arabic text normalization + better tokenization
"""
import re
from langchain_core.documents import Document
from rank_bm25 import BM25Okapi
from config import TOP_K_RESULTS


# ============================================================
# Arabic Text Normalization
# ============================================================

# خريطة توحيد الحروف العربية
_ARABIC_NORMALIZE_MAP = {
    'إ': 'ا', 'أ': 'ا', 'آ': 'ا', 'ٱ': 'ا',  # توحيد الهمزات
    'ة': 'ه',  # التاء المربوطة
    'ى': 'ي',  # الألف المقصورة
    'ؤ': 'و',  # الهمزة على واو
    'ئ': 'ي',  # الهمزة على ياء
}

# التشكيل العربي (فتحة، كسرة، ضمة، سكون، شدة، تنوين)
_TASHKEEL_PATTERN = re.compile(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED]')

# أحرف التكرار الزائدة (مثل: جمييييل → جميل)
_REPEATED_CHARS = re.compile(r'(.)\1{2,}')

# Stop words عربية شائعة
_ARABIC_STOP_WORDS = {
    'في', 'من', 'على', 'إلى', 'الى', 'عن', 'مع', 'هذا', 'هذه',
    'ذلك', 'تلك', 'هو', 'هي', 'هم', 'هن', 'أنت', 'أنا', 'نحن',
    'الذي', 'التي', 'الذين', 'اللاتي', 'ما', 'لا', 'لم', 'لن',
    'قد', 'كان', 'كانت', 'يكون', 'تكون', 'ليس', 'ليست',
    'أن', 'إن', 'لو', 'لولا', 'حتى', 'لكن', 'بل', 'ثم',
    'و', 'أو', 'ف', 'ب', 'ل', 'ك', 'ال',
    'كل', 'بعض', 'أي', 'كيف', 'أين', 'متى', 'لماذا',
    'بين', 'عند', 'بعد', 'قبل', 'فوق', 'تحت', 'حول',
    'هنا', 'هناك', 'الآن', 'أيضا', 'جدا', 'ثم', 'أو',
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at',
    'to', 'for', 'of', 'and', 'or', 'but', 'not', 'with', 'from',
    'by', 'this', 'that', 'it', 'be', 'as', 'do', 'does',
}


def normalize_arabic(text: str) -> str:
    """تطبيع النص العربي — إزالة التشكيل، توحيد الحروف، تنظيف."""
    if not text:
        return ""

    # إزالة التشكيل
    text = _TASHKEEL_PATTERN.sub('', text)

    # توحيد الحروف
    for old, new in _ARABIC_NORMALIZE_MAP.items():
        text = text.replace(old, new)

    # إزالة التكرار الزائد (جميييل → جميل)
    text = _REPEATED_CHARS.sub(r'\1\1', text)

    # تحويل لأحرف صغيرة (للإنجليزي)
    text = text.lower()

    return text


def tokenize_arabic(text: str, remove_stopwords: bool = True) -> list[str]:
    """تقسيم النص العربي لكلمات مع تطبيع و stemming بسيط."""
    text = normalize_arabic(text)

    # تقسيم على المسافات وعلامات الترقيم
    tokens = re.split(r'[\s\.,،؛:!؟?\-\(\)\[\]\"\']+', text)

    # تنظيف
    tokens = [t.strip() for t in tokens if t.strip() and len(t.strip()) > 1]

    # إزالة Stop Words
    if remove_stopwords:
        tokens = [t for t in tokens if t not in _ARABIC_STOP_WORDS]

    # Stemming بسيط
    stemmed_tokens = []
    for t in tokens:
        if t.startswith('ال') and len(t) > 3:
            t = t[2:]
        if t.endswith('ات') and len(t) > 3:
            t = t[:-2]
        elif t.endswith('ون') and len(t) > 3:
            t = t[:-2]
        elif t.endswith('ين') and len(t) > 3:
            t = t[:-2]
        elif t.endswith('ه') and len(t) > 2:
            t = t[:-1]
        
        if len(t) > 1:
            stemmed_tokens.append(t)

    return stemmed_tokens


# ============================================================
# BM25 Store
# ============================================================

class BM25Store:
    """فهرس BM25 للبحث بالكلمات المفتاحية — محسّن للعربية."""

    def __init__(self):
        self._index: BM25Okapi | None = None
        self._docs: list[Document] = []
        self._tokenized: list[list[str]] = []

    def build_index(self, documents: list[Document]):
        """بناء فهرس BM25 من المستندات مع Arabic normalization."""
        self._docs = documents
        self._tokenized = [
            tokenize_arabic(doc.page_content, remove_stopwords=True)
            for doc in documents
        ]

        # إزالة المستندات الفارغة بعد التطبيع
        valid = [(doc, tokens) for doc, tokens in zip(self._docs, self._tokenized) if tokens]
        if valid:
            self._docs, self._tokenized = zip(*valid)
            self._docs = list(self._docs)
            self._tokenized = list(self._tokenized)
        else:
            self._docs = []
            self._tokenized = []

        if self._tokenized:
            self._index = BM25Okapi(self._tokenized)

        print(f"🔤 فهرس BM25 جاهز — {len(self._docs)} مستند (Arabic-normalized)")

    def search(self, query: str, top_k: int = TOP_K_RESULTS) -> list[tuple[Document, float]]:
        """بحث بالكلمات المفتاحية مع Arabic normalization."""
        if not self._index or not self._docs:
            return []

        tokenized_query = tokenize_arabic(query, remove_stopwords=False)

        if not tokenized_query:
            # لو بعد التطبيع مفيش كلمات → نحاول بدون stop words removal
            tokenized_query = normalize_arabic(query).split()

        if not tokenized_query:
            return []

        scores = self._index.get_scores(tokenized_query)

        # ترتيب حسب النتيجة
        top_indices = sorted(
            range(len(scores)),
            key=lambda i: scores[i],
            reverse=True
        )[:top_k]

        return [
            (self._docs[i], float(scores[i]))
            for i in top_indices
            if scores[i] > 0
        ]

    @property
    def is_ready(self) -> bool:
        return self._index is not None

    @property
    def doc_count(self) -> int:
        return len(self._docs)


# مثيل عام واحد
bm25_store = BM25Store()
