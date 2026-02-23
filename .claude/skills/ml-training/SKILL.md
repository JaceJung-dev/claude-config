---
name: ml-training
description: Guidelines for machine learning model training, fine-tuning, and inference with PyTorch and Hugging Face Transformers. Use when training models, fine-tuning LLMs, running inference, quantizing models, or working with datasets. Triggers on tasks involving pytorch, transformers, datasets, training loops, model optimization, quantization, or GPU compute.
---

# ML Training

PyTorch and Hugging Face Transformers for training, fine-tuning, and inference.
Includes Transformers v5 breaking changes that differ from training data.

## When to Apply

- Model training / fine-tuning
- Inference pipelines
- Quantization and optimization
- Dataset preprocessing
- PyTorch training loops

## Critical: Transformers v5 Breaking Changes

### Quantization Config (replaces load_in_8bit/4bit)

```python
# OLD (broken in v5)
model = AutoModelForCausalLM.from_pretrained("model", load_in_8bit=True)

# NEW (v5+)
from transformers import BitsAndBytesConfig, AutoModelForCausalLM

quantization_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True,
)
model = AutoModelForCausalLM.from_pretrained(
    "model",
    quantization_config=quantization_config,
    device_map="auto",
)
```

### HTTP Client: `httpx` replaces `requests`

Transformers v5 uses `httpx` internally. If you intercept or mock HTTP calls, update accordingly.

### Tokenizer: `text_target` replaces `as_target_tokenizer()`

```python
# OLD (broken in v5)
with tokenizer.as_target_tokenizer():
    labels = tokenizer(target_text)

# NEW (v5+)
labels = tokenizer(text_target=target_text)
```

### Trainer: `processing_class` replaces `tokenizer`

```python
# OLD
trainer = Trainer(model=model, tokenizer=tokenizer, ...)

# NEW (v5+)
trainer = Trainer(model=model, processing_class=tokenizer, ...)
```

### TrainingArguments: `eval_strategy` replaces `evaluation_strategy`

```python
# OLD
TrainingArguments(evaluation_strategy="epoch")

# NEW (v5+)
TrainingArguments(eval_strategy="epoch")
```

### Model Loading: `dtype="auto"`

```python
# Loads weights in their stored dtype (avoids double-loading in float32)
model = AutoModelForCausalLM.from_pretrained("model", dtype="auto", device_map="auto")
```

### Tokenizer Backend Architecture

Old "fast" vs "slow" distinction replaced with backends:
`TokenizersBackend` (Rust, default), `SentencePieceBackend`, `PythonBackend`, `MistralCommonBackend`.
Check with `tokenizer.backend`.

### Special Tokens Map

`special_tokens_map` structure has been restructured in v5. Check docs if accessing directly.

## PyTorch Patterns

Claude knows PyTorch well. Key conventions only:

- Use `torch.compile(model)` for production speed (PyTorch 2.x+)
- Use `torch.cuda.amp.autocast()` + `GradScaler` for mixed precision
- Always use `model.eval()` + `torch.no_grad()` for inference
- Save with `torch.save(model.state_dict(), path)`, load with `load_state_dict`
- Use `DistributedDataParallel` (not `DataParallel`) for multi-GPU
- Pin memory in DataLoader: `pin_memory=True` for GPU training

```python
# Standard training loop structure
optimizer = torch.optim.AdamW(model.parameters(), lr=1e-5, weight_decay=0.01)
scaler = torch.amp.GradScaler()

for epoch in range(num_epochs):
    model.train()
    for batch in dataloader:
        optimizer.zero_grad()
        with torch.amp.autocast(device_type="cuda"):
            loss = model(**batch).loss
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
```

## Hugging Face Patterns

**Model loading:**
```python
from transformers import AutoModelForCausalLM, AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained("model-name")
model = AutoModelForCausalLM.from_pretrained(
    "model-name",
    dtype="auto",
    device_map="auto",
)
```

**Trainer for fine-tuning:**
```python
from transformers import Trainer, TrainingArguments

training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    learning_rate=2e-5,
    bf16=True,
    logging_steps=10,
    save_strategy="epoch",
    eval_strategy="epoch",
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    processing_class=tokenizer,
)
trainer.train()
```

**Pipeline for quick inference:**
```python
from transformers import pipeline

pipe = pipeline("text-generation", model="model-name", device_map="auto")
result = pipe("Hello, world!", max_new_tokens=100)
```

## LoRA / PEFT Fine-tuning

```python
from peft import LoraConfig, get_peft_model, TaskType

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,
    lora_alpha=32,
    lora_dropout=0.05,
    target_modules=["q_proj", "v_proj"],
)
model = get_peft_model(model, lora_config)
```

## Anti-Patterns

- **Do NOT** use `load_in_8bit=True` — use `quantization_config` (v5)
- **Do NOT** use `as_target_tokenizer()` — use `text_target` parameter (v5)
- **Do NOT** use `DataParallel` — use `DistributedDataParallel`
- **Do NOT** forget `model.eval()` during inference
- **Do NOT** load full precision models when quantized will suffice
- **Do NOT** skip gradient checkpointing for large model training
- **Do NOT** use `Trainer(tokenizer=)` — use `processing_class=` (v5)
- **Do NOT** use `evaluation_strategy` — use `eval_strategy` (v5)

## Project Structure

```
src/
  models/           # Model definitions
  training/         # Training scripts
  inference/        # Inference pipelines
  data/             # Dataset processing
  configs/          # Training configs (YAML)
  utils/            # Metrics, logging, checkpoints
scripts/
  train.py
  evaluate.py
  inference.py
```

## Before Implementing

Verify Transformers API with context7 — v5 has significant breaking changes.
Check PyTorch version compatibility with `torch.__version__`.
