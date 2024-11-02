using Test
using Sage

@testset "Sage.jl" begin
    @testset "Initialization" begin
        sage = JJAI()
        @test sage isa JJAI
        @test isempty(sage.documents)
        @test isempty(sage.doc_embeddings)
        @test isempty(sage.vocab)
        cleanup!(sage)
    end

    @testset "Learning and Answering" begin
        sage = JJAI()
        
        # Test learning
        learn!(sage, "Julia is a fast programming language.")
        @test length(sage.documents) == 1
        @test length(sage.doc_embeddings) == 1
        @test !isempty(sage.vocab)
        
        # Test simple answer
        response = answer(sage, "Tell me about Julia")
        @test response isa String
        @test !isempty(response)
        @test response != "No knowledge yet."
        
        # Test unknown question
        response = answer(sage, "What is the meaning of life?")
        @test response isa String
        @test contains(response, "don't have enough information") || contains(response, "confident")
        
        cleanup!(sage)
    end

    @testset "Database Operations" begin
        db_path = "test_sage.duckdb"
        sage = JJAI(db_path)
        
        # Test persistence
        learn!(sage, "Test document 1")
        learn!(sage, "Test document 2")
        cleanup!(sage)
        
        # Load again and check persistence
        sage2 = JJAI(db_path)
        @test length(sage2.documents) == 2
        @test length(sage2.doc_embeddings) == 2
        cleanup!(sage2)
        
        # Clean up test database
        rm(db_path, force=true)
    end

    @testset "Reset Knowledge" begin
        sage = JJAI()
        
        # Add some documents
        learn!(sage, "Document 1")
        learn!(sage, "Document 2")
        
        # Reset knowledge
        reset_knowledge!(sage)
        
        @test isempty(sage.documents)
        @test isempty(sage.doc_embeddings)
        @test isempty(sage.vocab)
        
        cleanup!(sage)
    end

    @testset "Transformer Components" begin
        sage = JJAI()
        
        # Test positional encoding
        @test size(sage.positional_enc) == (sage.config.max_seq_length, sage.config.d_model)
        
        # Test text encoding
        embeddings = Sage.encode_text(sage, "test text")
        @test size(embeddings, 1) == sage.config.d_model
        
        cleanup!(sage)
    end
end
