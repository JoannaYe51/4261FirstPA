//
//  ContentView.swift
//  guessTheFlag
//
//  Created by yqw on 2022/11/2.
//

import SwiftUI
import Foundation

struct FlagView: View {
    let flagCountry: String
    var body: some View {
        Image(flagCountry).renderingMode(.original)
            .clipShape(Capsule())
            .shadow(radius: 5)
    }
}


struct ContentView: View {
    @State private var showingScore = false
    @State private var scoreTitle = ""
    @State private var score = 0
    @State private var times = 0
    @State private var isEnd = false
    @State private var countries = ["Estonia", "France", "Germany", "Ireland", "Italy", "Nigeria", "Poland", "Russia", "Spain", "UK", "US"].shuffled()
    @State private var correctAnswer = Int.random(in: 0...2)
    @State private var showingSaveConfirmation = false
    @State private var animationAmount = 0.0
    @State private var opacityAmount = 1.0
    @State private var tappedNumber = 0
    
    struct Flag: ViewModifier {
        var flagCountry: String
        
        func body(content: Content) -> some View {
            Image(flagCountry).renderingMode(.original)
                .clipShape(Capsule())
                .shadow(radius: 5)
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.48), Color(red: 0.78, green: 0.15, blue: 0.24)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                Text("Guess the Flag")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                VStack(spacing: 20) {
                    VStack {
                        Text("Tag the flag of")
                            .foregroundColor(.secondary)
                            .font(.subheadline.weight(.heavy))
                        Text(countries[correctAnswer])
                            .foregroundColor(.primary)
                            .font(.largeTitle.weight(.semibold))
                    }
                    
                    ForEach(0..<3) { number in
                        Button {
                            opacityAmount = 0.75
                            flagTapped(number)
                        } label: {
                            FlagView(flagCountry: countries[number])
                        }
                        .opacity(number == tappedNumber ? 1 : opacityAmount)
                        .rotation3DEffect(.degrees(number == tappedNumber ? animationAmount : 0.0), axis: (x: 0, y: 1, z: 0))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Spacer()
                Spacer()
                HStack {
                    Spacer()
                    Text("Score: \(score)")
                        .foregroundColor(.white)
                        .font(.title.bold())
                    Spacer()
                    Button("Save Score") {
                        showingSaveConfirmation = true
                    }
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
            
            .alert(scoreTitle, isPresented: $showingScore) {
                Button("Continue", action: askQuestion)
            } message: {
                Text("Your score is \(score)")
            }
            .alert("Times up!", isPresented: $isEnd) {
                Button("Play again", action: restart)
            }
        }.alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("Save Score"),
                message: Text("Do you want to save your current score of \(score)?"),
                primaryButton: .default(Text("Yes")) {
                    // Call your save score function here
                    saveScore(score: score)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func flagTapped(_ number: Int) {
        tappedNumber = number
        if number == correctAnswer {
            scoreTitle = "Correct!"
            score += 1
            withAnimation(.interpolatingSpring(stiffness: 20, damping: 5)) {
                animationAmount += 360
            }
        } else {
            scoreTitle = "Wrong! That's the flag of \(countries[correctAnswer])!"
            withAnimation(.interpolatingSpring(stiffness: 20, damping: 5)) {
                animationAmount += 360
            }
        }
        showingScore = true
    }
    
    func askQuestion() {
        countries.shuffle()
        correctAnswer = Int.random(in: 0...2)
        times += 1
        
        if times == 8 {
            isEnd = true
        }
        
        opacityAmount = 1
    }
    
    func restart() {
        opacityAmount = 1
        countries.shuffle()
        correctAnswer = Int.random(in: 0...2)
        times = 0
        score = 0
    }
}

func saveScore(score: Int) {
    guard let apiUrl = URL(string: "http://124.221.179.133:5000/save_score") else { return }
    var request = URLRequest(url: apiUrl)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = ["user_id": "user", "score": score]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        print("Error encoding score data: \(error)")
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Failed to save score data: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response from the server")
            return
        }
        
        if httpResponse.statusCode == 200 {
            print("Score data submitted successfully")
        } else {
            print("Failed to submit score data. Status code: \(httpResponse.statusCode)")
        }
    }.resume()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
