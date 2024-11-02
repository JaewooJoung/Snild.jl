using Test
using Sage
using Random

@testset "Sage.jl" begin
    # Create temp directory for test databases
    test_dir = mktempdir()

    @testset "Initialization" begin
        db_path = joinpath(test_dir, "init_test.duckdb")
        sage = JJAI(db_path)
        @test sage isa JJAI
        @test isempty(sage.documents)
        @test isempty(sage.doc_embeddings)
        cleanup!(sage)
    end

    @testset "Learning and Answering" begin
        db_path = joinpath(test_dir, "learn_test.duckdb")
        sage = JJAI(db_path)

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

        cleanup!(sage)
    end

    @testset "Database Operations" begin
        db_path = joinpath(test_dir, "persist_test.duckdb")

        # Create first instance
        sage1 = JJAI(db_path)
        learn!(sage1, "Test document 1")
        learn!(sage1, "Test document 2")
        cleanup!(sage1)

        # Create second instance with same database
        sage2 = JJAI(db_path)
        @test length(sage2.documents) == 2
        @test length(sage2.doc_embeddings) == 2
        cleanup!(sage2)
    end

    @testset "Reset Knowledge" begin
        db_path = joinpath(test_dir, "reset_test.duckdb")
        sage = JJAI(db_path)

        # Add some documents
        learn!(sage, "Document 1")
        learn!(sage, "Document 2")
        @test length(sage.documents) == 2

        # Reset knowledge
        Sage.reset_knowledge!(sage)

        @test isempty(sage.documents)
        @test isempty(sage.doc_embeddings)
        @test isempty(sage.vocab)

        cleanup!(sage)
    end

    @testset "Transformer Components" begin
        db_path = joinpath(test_dir, "transformer_test.duckdb")
        sage = JJAI(db_path)

        # Test positional encoding
        @test size(sage.positional_enc) == (sage.config.max_seq_length, sage.config.d_model)

        # Test text encoding
        text = "test text"
        embeddings = encode_text(sage, text)
        @test size(embeddings, 1) == sage.config.d_model

        cleanup!(sage)
    end

    # Clean up test directory
    rm(test_dir, recursive=true, force=true)
end
