using Test
using Sage

@testset "Sage.jl" begin
    @testset "Initialization" begin
        sage = JJAI()
        @test sage isa JJAI
        @test isempty(sage.documents)
        @test isempty(sage.doc_embeddings)
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

        cleanup!(sage)
    end

    @testset "Database Operations" begin
        db_path = tempname() * ".duckdb"
        try
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
        finally
            # Clean up test database
            rm(db_path, force=true)
        end
    end

    @testset "Reset Knowledge" begin
        sage = JJAI(tempname() * ".duckdb")
        try
            # Add some documents
            learn!(sage, "Document 1")
            learn!(sage, "Document 2")
            @test length(sage.documents) == 2

            # Reset knowledge
            reset_knowledge!(sage)

            @test isempty(sage.documents)
            @test isempty(sage.doc_embeddings)
            @test isempty(sage.vocab)

            cleanup!(sage)
        finally
            rm(sage.db_path, force=true)
        end
    end

    @testset "Transformer Components" begin
        sage = JJAI()

        # Test positional encoding
        @test size(sage.positional_enc) == (sage.config.max_seq_length, sage.config.d_model)

        # Test text encoding
        text = "test text"
        embeddings = Sage.encode_text(sage, text)
        @test size(embeddings, 1) == sage.config.d_model

        cleanup!(sage)
    end
end
