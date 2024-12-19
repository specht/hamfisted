import random

# Parameters
num_buckets = 25
correct_answers_needed = 19
questions_per_bucket = [8, 8, 7, 8, 8, 8, 8, 7, 8, 8, 8, 8, 7, 8, 8, 8, 8, 7, 8, 8, 8, 8, 7, 8, 8]
probabilities = [0.8] * 25
num_trials = 10000  # Number of trial exams

def simulate_exam(questions_per_bucket, probabilities):
    correct_answers = 0
    for i in range(num_buckets):
        num_questions = questions_per_bucket[i]
        prob_correct = probabilities[i]
        
        if random.random() < prob_correct:
            correct_answers += 1
    return correct_answers >= correct_answers_needed

def calculate_passing_probability(questions_per_bucket, probabilities, num_trials):
    passing_count = 0
    for _ in range(num_trials):
        if simulate_exam(questions_per_bucket, probabilities):
            passing_count += 1
    return passing_count / num_trials

# Calculate the probability of passing the exam
probability_passing = calculate_passing_probability(questions_per_bucket, probabilities, num_trials)
print(f"Estimated probability of passing the exam: {(probability_passing * 100.0):.2f}%")