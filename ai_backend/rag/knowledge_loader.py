"""
📚 Knowledge Loader — تحميل ملفات قاعدة المعرفة (Markdown)
"""
from langchain_core.documents import Document
from config import KNOWLEDGE_DIR


def load_knowledge_files() -> list[Document]:
    """تحميل ملفات Markdown كمستندات LangChain."""
    docs = []
    knowledge_dir = KNOWLEDGE_DIR

    if not knowledge_dir.exists():
        print("⚠️ مجلد المعرفة غير موجود، تم التخطي.")
        return docs

    for md_file in knowledge_dir.glob("*.md"):
        with open(md_file, "r", encoding="utf-8") as f:
            content = f.read()

        # تحديد النوع من اسم الملف
        doc_type = "history" if "history" in md_file.stem else "tourism"

        docs.append(Document(page_content=content, metadata={
            "source": "knowledge_base",
            "type": doc_type,
            "file": md_file.name,
        }))

    print(f"📚 تم تحميل {len(docs)} ملف معرفة")
    return docs
