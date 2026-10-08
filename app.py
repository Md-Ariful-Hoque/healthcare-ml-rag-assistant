
import streamlit as st
import ollama

from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity


# --------------------------------------------------
# Page setup
# --------------------------------------------------

st.set_page_config(
    page_title="Healthcare RAG Assistant",
    page_icon="🩺",
    layout="centered"
)

st.title("🩺 Healthcare RAG Assistant")

st.markdown(
    """
    Ask questions about the **Healthcare Hypertension Prediction Project**.

    This application uses **Retrieval-Augmented Generation (RAG)** to answer
    questions from the project knowledge base. Relevant evidence is retrieved
    using semantic similarity and provided to a locally running Llama model
    for grounded response generation.
    """
)

st.info(
    "This assistant is designed for project and data-analysis questions. "
    "It is not intended to provide medical diagnosis or treatment advice."
)

st.divider()


# --------------------------------------------------
# Load knowledge base and embedding model
# --------------------------------------------------

@st.cache_resource
def load_rag_system():

    with open(
        "knowledge/hypertension_project.txt",
        "r",
        encoding="utf-8"
    ) as f:
        knowledge_text = f.read()

    chunks = [
        chunk.strip()
        for chunk in knowledge_text.split("\n\n")
        if chunk.strip()
    ]

    model = SentenceTransformer(
        "all-MiniLM-L6-v2"
    )

    chunk_embeddings = model.encode(
        chunks,
        convert_to_numpy=True
    )

    return chunks, model, chunk_embeddings


chunks, embedding_model, chunk_embeddings = load_rag_system()


# --------------------------------------------------
# Retrieval
# --------------------------------------------------

def retrieve_chunks(question, top_k=3):

    question_embedding = embedding_model.encode(
        [question],
        convert_to_numpy=True
    )

    similarities = cosine_similarity(
        question_embedding,
        chunk_embeddings
    )[0]

    top_indices = similarities.argsort()[::-1][:top_k]

    retrieved = []

    for index in top_indices:

        retrieved.append({
            "chunk": chunks[index],
            "score": float(similarities[index])
        })

    return retrieved


# --------------------------------------------------
# RAG generation
# --------------------------------------------------

def ask_rag(question, top_k=3):

    retrieved = retrieve_chunks(
        question,
        top_k=top_k
    )

    context = "\n\n".join(
        [item["chunk"] for item in retrieved]
    )

    prompt = f"""
You are a healthcare data analysis assistant.

Your task is to answer the QUESTION strictly from the supplied CONTEXT.

IMPORTANT RULES:
1. Use ONLY information explicitly stated in the CONTEXT.
2. Do NOT use outside knowledge.
3. Do NOT guess or infer unsupported conclusions.
4. Read ALL retrieved chunks before answering.
5. Give priority to the chunk that most directly answers the QUESTION.
6. If the context says two models performed similarly or nearly identically,
   do NOT select one model as the winner.
7. Your answer must be directly supported by the CONTEXT.
8. If the answer is not explicitly supported by the CONTEXT, say exactly:
   "I cannot answer this from the provided knowledge base."

CONTEXT:
{context}

QUESTION:
{question}

ANSWER:
"""

    response = ollama.chat(
        model="llama3.2",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        options={
            "temperature": 0.2
        }
    )

    return {
        "answer": response["message"]["content"],
        "retrieved_chunks": retrieved
    }


# --------------------------------------------------
# User interface
# --------------------------------------------------

st.subheader("Ask the Assistant")

st.markdown("**Example questions:**")

st.markdown(
    """
    - Which machine learning models were evaluated?
    - Why is temporal alignment important?
    - How did Logistic Regression and Random Forest compare after temporal redesign?
    - What were the limitations of the study?
    """
)

question = st.text_input(
    "Enter your question:",
    placeholder="Ask about the healthcare ML project..."
)

if question:

    with st.spinner("Generating answer..."):

        result = ask_rag(question)

    st.subheader("Answer")

    st.write(
        result["answer"]
    )

    st.subheader("Retrieved Evidence")

    for i, item in enumerate(
        result["retrieved_chunks"],
        start=1
    ):

        with st.expander(
            f"Chunk {i} — Similarity: {item['score']:.3f}"
        ):

            st.write(
                item["chunk"]
            )
