using Test
using Snild
using Random

@testset "Snild.jl" begin
    # Create temp directory for test databases
    test_dir = mktempdir()

    @testset "Initialization" begin
        db_path = joinpath(test_dir, "init_test.duckdb")
        Snild = JJAI(db_path)
        @test Snild isa JJAI
        @test isempty(Snild.documents)
        @test isempty(Snild.doc_embeddings)
        cleanup!(Snild)
    end

    @testset "Learning and Answering" begin
        db_path = joinpath(test_dir, "learn_test.duckdb")
        Snild = JJAI(db_path)

        # Test learning
        learn!(Snild, "Julia is a fast programming language.")
        @test length(Snild.documents) == 1
        @test length(Snild.doc_embeddings) == 1
        @test !isempty(Snild.vocab)

        # Test simple answer
        response = answer(Snild, "Tell me about Julia")
        @test response isa String
        @test !isempty(response)
        @test response != "No knowledge yet."

        cleanup!(Snild)
    end

    @testset "Database Operations" begin
        db_path = joinpath(test_dir, "persist_test.duckdb")

        # Create first instance
        Snild1 = JJAI(db_path)
        learn!(Snild1, "Test document 1")
        learn!(Snild1, "Test document 2")
        cleanup!(Snild1)

        # Create second instance with same database
        Snild2 = JJAI(db_path)
        @test length(Snild2.documents) == 2
        @test length(Snild2.doc_embeddings) == 2
        cleanup!(Snild2)
    end

    @testset "Reset Knowledge" begin
        db_path = joinpath(test_dir, "reset_test.duckdb")
        Snild = JJAI(db_path)

        # Add some documents
        learn!(Snild, "Document 1")
        learn!(Snild, "Document 2")
        @test length(Snild.documents) == 2

        # Reset knowledge
        Snild.reset_knowledge!(Snild)

        @test isempty(Snild.documents)
        @test isempty(Snild.doc_embeddings)
        @test isempty(Snild.vocab)

        cleanup!(Snild)
    end

    @testset "Transformer Components" begin
        db_path = joinpath(test_dir, "transformer_test.duckdb")
        Snild = JJAI(db_path)

        # Test positional encoding
        @test size(Snild.positional_enc) == (Snild.config.max_seq_length, Snild.config.d_model)

        # Test text encoding
        text = "test text"
        embeddings = encode_text(Snild, text)
        @test size(embeddings, 1) == Snild.config.d_model

        cleanup!(Snild)
    end

    # Clean up test directory
    rm(test_dir, recursive=true, force=true)
end
