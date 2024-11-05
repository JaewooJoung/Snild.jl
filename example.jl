using Snild

#= Simple example showing how to use Snild for knowledge storage and retrieval =#
function basic_example()
    println("\n=== Basic Usage Example ===")

    # Initialize Snild
    oracle = JJAI("example_knowledge.duckdb")

    # Add some knowledge
    println("\nTeaching the oracle about programming languages...")
    learn!(oracle, "Julia is a high-performance programming language designed for numerical and scientific computing.")
    learn!(oracle, "Julia combines the speed of C with the dynamism of Ruby.")
    learn!(oracle, "Python is known for its simple syntax and extensive library ecosystem.")
    learn!(oracle, "Python is widely used in data science and machine learning.")
    learn!(oracle, "R is a programming language specifically designed for statistical computing.")
    learn!(oracle, "R has powerful packages for data visualization like ggplot2.")

    # Ask questions
    println("\nAsking questions...")
    questions = [
        "What is Julia good for?",
        "Tell me about Python's strengths",
        "Which language is best for statistics?",
        "What makes Julia fast?"
    ]

    for question in questions
        println("\nQ: $question")
        println("A: ", answer(oracle, question))
    end

    # Clean up
    cleanup!(oracle)
end

#= Example showing how to use Snild for technical documentation =#
function technical_docs_example()
    println("\n=== Technical Documentation Example ===")

    # Initialize with a specific database
    oracle = JJAI("tech_docs.duckdb")

    # Add technical documentation
    println("\nLoading technical documentation...")
    learn!(oracle, "To create a DataFrame in Julia, use: df = DataFrame(a=[1,2,3], b=['x','y','z'])")
    learn!(oracle, "DataFrame columns can be accessed using df.column_name or df[:, :column_name]")
    learn!(oracle, "Join DataFrames using innerjoin(df1, df2, on=:key_column)")
    learn!(oracle, "Filter DataFrames using: filter(row -> row.column > 5, df)")
    learn!(oracle, "Group operations: combine(groupby(df, :group_col), :value => mean)")

    # Query the documentation
    println("\nQuerying documentation...")
    questions = [
        "How do I create a DataFrame?",
        "How can I access DataFrame columns?",
        "How do I join DataFrames?",
        "How to filter DataFrame rows?"
    ]

    for question in questions
        println("\nQ: $question")
        println("A: ", answer(oracle, question))
    end

    cleanup!(oracle)
end

#= Example showing how to use Snild for a simple chatbot =#
function chatbot_example()
    println("\n=== Chatbot Example ===")

    # Initialize with personality
    oracle = JJAI("chatbot.duckdb")

    # Add personality and knowledge
    println("\nInitializing chatbot personality...")
    learn!(oracle, "I am a helpful AI assistant who aims to provide clear and concise answers.")
    learn!(oracle, "When greeted, I respond warmly and professionally.")
    learn!(oracle, "If I don't know something, I admit it honestly.")
    learn!(oracle, "I try to be empathetic and understanding in my responses.")

    # Add some domain knowledge
    learn!(oracle, "The weather affects many aspects of our daily life and planning.")
    learn!(oracle, "Regular exercise is important for maintaining both physical and mental health.")
    learn!(oracle, "A balanced diet includes proteins, carbohydrates, fats, vitamins, and minerals.")

    # Simulate a conversation
    println("\nStarting conversation...")
    conversations = [
        "Hello, how are you?",
        "What's the importance of exercise?",
        "Can you tell me about healthy eating?",
        "What's the meaning of life?",  # Something it doesn't know
        "Goodbye!"
    ]

    for user_input in conversations
        println("\nUser: $user_input")
        println("Bot: ", answer(oracle, user_input))
    end

    cleanup!(oracle)
end

# Run all examples
println("Running Snild.jl Examples...")
println("==========================")

basic_example()
technical_docs_example()
chatbot_example()

println("\nExamples completed!")
