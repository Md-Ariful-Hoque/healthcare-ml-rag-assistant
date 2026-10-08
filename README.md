# Healthcare Outcome Prediction and RAG Assistant

## Project Overview

This project combines SQL, Python, machine learning, and Retrieval-Augmented Generation (RAG) to analyze synthetic healthcare data and build a local AI assistant for interpreting project findings.

## Technologies

- MySQL and SQL
- Python, pandas, scikit-learn
- Logistic Regression and Random Forest
- Sentence Transformers (all-MiniLM-L6-v2)
- Ollama with Llama 3.2
- Streamlit

## Machine Learning Analysis

The final temporally designed cohort contains 312 patients:
- 156 hypertension cases
- 156 age-matched controls

The project evaluates Logistic Regression and Random Forest for hypertension prediction.

Held-out ROC-AUC:
- Logistic Regression: 0.744
- Random Forest: 0.688

After temporal redesign, the two models demonstrated nearly identical cross-validated discrimination.

Temporal alignment was used to reduce the risk of data leakage.

## Retrieval-Augmented Generation

The assistant:
1. Loads the project knowledge base.
2. Splits documents into text chunks.
3. Generates sentence embeddings.
4. Retrieves the three most similar chunks.
5. Sends the retrieved context to a local Llama 3.2 model.
6. Displays answers and supporting evidence in Streamlit.

## Preliminary RAG Evaluation

Five questions were used for an initial evaluation.

- Answerable questions: 3
- Unanswerable questions: 2
- Rule-based accuracy: 100%
- Retrieval Hit@1: 66.7%
- Retrieval Hit@3: 100%

These results are preliminary and should not be interpreted as evidence of general RAG accuracy.

## Run the Application

Install Python dependencies:

```bash
pip install -r requirements.txt
```

Install Ollama separately, then download the model:

```bash
ollama pull llama3.2
```

Start the Streamlit application:

```bash
streamlit run app.py
```

The application runs locally and does not require a paid LLM API.

## Limitations

- Synthetic healthcare data
- Relatively small cohort
- Limited pre-index healthcare information
- Only two prediction models evaluated
- Small preliminary RAG evaluation set

## Disclaimer

This application is intended for research and educational purposes. It does not provide medical diagnosis or treatment recommendations.
