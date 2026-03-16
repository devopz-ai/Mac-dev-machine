# AI/ML Development Guide

Tools and workflows for local LLM development, AI applications, and machine learning on Mac.

## Tool Stack

| Category | Tools |
|----------|-------|
| LLM Runtime | Ollama, LM Studio, GPT4All, llama.cpp |
| Frameworks | LangChain, LlamaIndex, Hugging Face |
| Vector DBs | ChromaDB, Qdrant, Milvus |
| Image Gen | DiffusionBee, Draw Things |
| SDKs | OpenAI, Anthropic |

---

## Local LLM Setup

### Ollama (Recommended)

```bash
# Install (already done via brew)
brew install ollama

# Start server
ollama serve
# → Runs on http://localhost:11434

# In another terminal, pull models
ollama pull llama2           # General purpose (7B)
ollama pull codellama        # Coding tasks
ollama pull mistral          # Fast, quality balance
ollama pull mixtral          # Larger, better quality

# Interactive chat
ollama run llama2
>>> Hello, how are you?

# List models
ollama list

# Remove model
ollama rm llama2
```

### Model Selection Guide

| Model | Size | Use Case | Speed |
|-------|------|----------|-------|
| llama2 | 7B | General chat | Fast |
| llama2:13b | 13B | Better quality | Medium |
| codellama | 7B | Code generation | Fast |
| mistral | 7B | Quality/speed balance | Fast |
| mixtral | 8x7B | Complex tasks | Slow |
| phi | 2.7B | Small, fast | Very fast |

### LM Studio (GUI Alternative)

```bash
# Open LM Studio
open -a "LM Studio"

# Features:
# - Browse/download models from Hugging Face
# - Chat interface
# - OpenAI-compatible API at localhost:1234
```

---

## Python Environment Setup

```bash
# Create project
mkdir ai-project && cd ai-project
python -m venv .venv
source .venv/bin/activate

# Install core packages
pip install langchain langchain-community
pip install chromadb
pip install sentence-transformers
pip install openai anthropic

# For Ollama integration
pip install langchain-ollama

# For Jupyter notebooks
pip install jupyterlab ipykernel
python -m ipykernel install --user --name=ai-project
```

---

## LangChain Workflows

### Basic Ollama Chat

```python
from langchain_community.llms import Ollama

# Initialize
llm = Ollama(model="llama2")

# Simple query
response = llm.invoke("Explain quantum computing in simple terms")
print(response)
```

### Chat with Memory

```python
from langchain_community.llms import Ollama
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

llm = Ollama(model="llama2")
memory = ConversationBufferMemory()
conversation = ConversationChain(llm=llm, memory=memory)

# Chat with context
response1 = conversation.predict(input="My name is Alice")
response2 = conversation.predict(input="What's my name?")
# → "Your name is Alice"
```

### Prompt Templates

```python
from langchain.prompts import PromptTemplate
from langchain_community.llms import Ollama

template = """You are a helpful assistant. Answer the question below.

Question: {question}
Answer:"""

prompt = PromptTemplate(template=template, input_variables=["question"])
llm = Ollama(model="llama2")

chain = prompt | llm
response = chain.invoke({"question": "What is Python?"})
```

---

## RAG (Retrieval Augmented Generation)

### Setup ChromaDB

```python
import chromadb
from chromadb.config import Settings

# Create client
client = chromadb.Client(Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="./chroma_db"
))

# Create collection
collection = client.create_collection("my_docs")

# Add documents
collection.add(
    documents=["Doc 1 content", "Doc 2 content"],
    ids=["doc1", "doc2"],
    metadatas=[{"source": "file1"}, {"source": "file2"}]
)

# Query
results = collection.query(
    query_texts=["search query"],
    n_results=2
)
```

### Complete RAG Pipeline

```python
from langchain_community.llms import Ollama
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA

# 1. Load and split documents
from langchain_community.document_loaders import TextLoader
loader = TextLoader("document.txt")
documents = loader.load()

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200
)
splits = text_splitter.split_documents(documents)

# 2. Create embeddings and vector store
embeddings = OllamaEmbeddings(model="llama2")
vectorstore = Chroma.from_documents(splits, embeddings)

# 3. Create retrieval chain
llm = Ollama(model="llama2")
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=vectorstore.as_retriever(),
    return_source_documents=True
)

# 4. Query
result = qa_chain.invoke({"query": "What is the main topic?"})
print(result["result"])
```

---

## Cloud LLM APIs

### OpenAI

```python
from openai import OpenAI

client = OpenAI()  # Uses OPENAI_API_KEY env var

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

### Anthropic (Claude)

```python
from anthropic import Anthropic

client = Anthropic()  # Uses ANTHROPIC_API_KEY env var

response = client.messages.create(
    model="claude-3-opus-20240229",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Hello, Claude!"}
    ]
)
print(response.content[0].text)
```

### LiteLLM (Unified API)

```python
from litellm import completion

# Works with any provider
response = completion(
    model="ollama/llama2",  # or "gpt-4", "claude-3-opus"
    messages=[{"role": "user", "content": "Hello"}]
)
print(response.choices[0].message.content)
```

---

## AI Image Generation

### DiffusionBee

```bash
# Open app
open -a DiffusionBee

# Features:
# - Text to image
# - Image to image
# - Inpainting
# - Runs locally with Metal acceleration
```

### Draw Things

```bash
# Open app
open -a "Draw Things"

# Features:
# - Multiple model support
# - ControlNet
# - LoRA support
# - Native Apple Silicon optimization
```

---

## Vector Database Options

### Qdrant

```bash
# Start Qdrant
docker run -p 6333:6333 qdrant/qdrant

# Or install locally
brew install qdrant
qdrant
```

```python
from qdrant_client import QdrantClient

client = QdrantClient("localhost", port=6333)

# Create collection
client.create_collection(
    collection_name="my_collection",
    vectors_config={"size": 384, "distance": "Cosine"}
)
```

### Milvus

```bash
# Start with Docker
docker-compose up -d  # Use Milvus docker-compose
```

---

## AI Coding Assistants

### Aider

```bash
# Install
pip install aider-chat

# Use with Ollama
aider --model ollama/codellama

# Use with OpenAI
export OPENAI_API_KEY=sk-xxx
aider

# Common commands in aider:
# /add file.py     - Add file to context
# /drop file.py    - Remove file
# /diff            - Show changes
# /undo            - Undo last change
```

### Open Interpreter

```bash
# Install
pip install open-interpreter

# Run
interpreter

# Or with specific model
interpreter --model ollama/codellama
```

---

## Jupyter Workflows

```bash
# Start Jupyter
jupyter lab

# Or specific kernel
jupyter lab --notebook-dir=~/Projects
```

### Useful Extensions

```bash
pip install jupyterlab-lsp
pip install jupyterlab-git
```

---

## Performance Tips (Apple Silicon)

| Tip | Description |
|-----|-------------|
| Use Metal | Ollama auto-uses Metal GPU acceleration |
| Model size | 7B models run well, 13B+ need 16GB+ RAM |
| Quantization | Use Q4 quantized models for speed |
| Batch size | Reduce for lower memory usage |
| Concurrent | Ollama handles one request at a time |

### Memory Requirements

| Model Size | RAM Needed |
|------------|------------|
| 7B (Q4) | 8GB |
| 13B (Q4) | 16GB |
| 30B (Q4) | 32GB |
| 70B (Q4) | 64GB+ |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Ollama slow | Check model size, use smaller/quantized |
| Out of memory | Use smaller model, close other apps |
| Embeddings slow | Use smaller embedding model |
| ChromaDB errors | Check persist_directory permissions |
| API key invalid | Verify env var is set: `echo $OPENAI_API_KEY` |
