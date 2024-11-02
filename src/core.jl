# core.jl

# Constructor
function JJAI(db_path::String="sage.duckdb", config::TransformerConfig=DEFAULT_CONFIG)
    conn = DBInterface.connect(DuckDB.DB, db_path)
    init_database(conn)
    
    # Initialize transformer components
    positional_enc = positional_encoding(config.max_seq_length, config.d_model)
    
    # Load existing data
    documents, vocab, doc_embeddings, word_embeddings = load_data(conn, config)
    
    JJAI(
        documents,
        doc_embeddings,
        vocab,
        word_embeddings,
        positional_enc,
        config,
        Float32[],
        Dict{String,Any}(),
        db_path,
        conn
    )
end

# Tokenize and encode text
function encode_text(ai::JJAI, text::String)
    words = split(lowercase(text))
    seq_length = min(length(words), ai.config.max_seq_length)
    
    # Initialize empty embedding matrix
    embeddings = zeros(Float32, ai.config.d_model, seq_length)
    
    # Add word embeddings and positional encodings
    for (i, word) in enumerate(words[1:seq_length])
        if haskey(ai.vocab, word)
            word_idx = ai.vocab[word]
            embeddings[:, i] = ai.word_embeddings[:, word_idx]
        end
        embeddings[:, i] += ai.positional_enc[i, :]
    end
    
    return embeddings
end

# Transformer encoder
function transformer_encode(ai::JJAI, embeddings::Matrix{Float32})
    # Multi-head attention
    attn_output = multi_head_attention(
        embeddings,  # Q
        embeddings,  # K
        embeddings,  # V
        ai.config.n_head,
        ai.config.d_model
    )
    
    # Add & Norm
    attn_output = attn_output + embeddings
    attn_output = layer_norm(attn_output)
    
    # Feed-forward network
    ff_output = feed_forward(attn_output, ai.config.d_ff)
    
    # Add & Norm
    ff_output = ff_output + attn_output
    ff_output = layer_norm(ff_output)
    
    # Return mean pooling of the sequence
    return vec(mean(ff_output, dims=2))
end

function learn!(ai::JJAI, text::String)
    # Add to documents
    push!(ai.documents, text)
    
    # Update vocabulary
    words = split(lowercase(text))
    vocab_changed = false
    for word in words
        if !haskey(ai.vocab, word)
            vocab_changed = true
            ai.vocab[word] = length(ai.vocab) + 1
            
            DBInterface.execute(ai.conn, """
                INSERT INTO vocabulary (word, index) VALUES (?, ?)
            """, (word, ai.vocab[word]))
        end
    end
    
    # Initialize/update word embeddings if vocabulary size changed
    vocab_size = length(ai.vocab)
    if vocab_changed || isempty(ai.word_embeddings)
        if isempty(ai.word_embeddings)
            ai.word_embeddings = randn(Float32, ai.config.d_model, vocab_size)
            
            for (word, idx) in ai.vocab
                vector_doubles = Float64.(ai.word_embeddings[:, idx])
                vector_list = "ARRAY[" * join(string.(vector_doubles), ",") * "]::DOUBLE[]"
                DBInterface.execute(ai.conn, """
                    INSERT INTO word_embeddings (vocab_index, vector)
                    VALUES (?, $vector_list)
                """, (idx,))
            end
        else
            old_size = size(ai.word_embeddings, 2)
            new_embeddings = zeros(Float32, ai.config.d_model, vocab_size)
            new_embeddings[:, 1:old_size] = ai.word_embeddings
            
            if vocab_size > old_size
                new_embeddings[:, (old_size+1):end] = randn(Float32, ai.config.d_model, vocab_size - old_size)
                
                for idx in (old_size+1):vocab_size
                    vector_doubles = Float64.(new_embeddings[:, idx])
                    vector_list = "ARRAY[" * join(string.(vector_doubles), ",") * "]::DOUBLE[]"
                    DBInterface.execute(ai.conn, """
                        INSERT INTO word_embeddings (vocab_index, vector)
                        VALUES (?, $vector_list)
                    """, (idx,))
                end
            end
            ai.word_embeddings = new_embeddings
        end
    end
    
    # Encode and transform the text
    text_embeddings = encode_text(ai, text)
    doc_embedding = transformer_encode(ai, text_embeddings)
    push!(ai.doc_embeddings, doc_embedding)
    
    # Get next document ID and save to database
    result = DBInterface.execute(ai.conn, "SELECT COALESCE(MAX(id), 0) + 1 FROM documents")
    next_id = first(result)[1]
    
    DBInterface.execute(ai.conn, "BEGIN TRANSACTION")
    try
        DBInterface.execute(ai.conn, """
            INSERT INTO documents (id, content) VALUES (?, ?)
        """, (next_id, text))
        
        vector_doubles = Float64.(doc_embedding)
        vector_list = "ARRAY[" * join(string.(vector_doubles), ",") * "]::DOUBLE[]"
        
        DBInterface.execute(ai.conn, """
            INSERT INTO embeddings (doc_id, vector) 
            VALUES (?, $vector_list)
        """, (next_id,))
        
        DBInterface.execute(ai.conn, "COMMIT")
    catch e
        DBInterface.execute(ai.conn, "ROLLBACK")
        rethrow(e)
    end
end

function answer(ai::JJAI, question::String)
    if isempty(ai.documents)
        return "No knowledge yet."
    end
    
    # Preprocess question to normalize it
    question = lowercase(strip(question))
    question_words = Set(split(question))
    
    # Initialize variables for finding best match
    best_score = -1.0
    best_doc = ""
    best_match_score = 0.0
    
    # First pass: Look for word overlap matches
    for doc in ai.documents
        doc_lower = lowercase(doc)
        doc_words = Set(split(doc_lower))
        
        # Calculate word overlap score
        total_matches = length(intersect(question_words, doc_words))
        match_score = total_matches / length(question_words)
        
        if match_score > best_match_score
            best_match_score = match_score
            best_doc = doc
        end
    end
    
    # If we found a good word overlap match, use it
    if best_match_score > 0.2
        return "($(@sprintf("%.2f", best_match_score * 100))% relevant) $best_doc"
    end
    
    # Fall back to embedding similarity if no good direct matches
    question_embeddings = encode_text(ai, question)
    question_embedding = transformer_encode(ai, question_embeddings)
    
    for (doc, embed) in zip(ai.documents, ai.doc_embeddings)
        q_norm = normalize(question_embedding)
        e_norm = normalize(embed)
        score = dot(q_norm, e_norm)
        
        if score > best_score
            best_score = score
            best_doc = doc
        end
    end
    
    if best_score > 0.3
        return "($(@sprintf("%.2f", best_score * 100))% confident) $best_doc"
    else
        return "I don't have enough information to answer that question confidently."
    end
end

function cleanup!(ai::JJAI)
    if ai.conn !== nothing
        try
            # Force a checkpoint to ensure all data is written to disk
            DBInterface.execute(ai.conn, "PRAGMA force_checkpoint")
            # Close the connection
            close(ai.conn)
        catch e
            # If there's an error during cleanup, at least close the connection
            close(ai.conn)
        end
    end
end
