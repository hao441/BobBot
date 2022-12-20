//
//  ContentView.swift
//  APICAll
//
//  Created by Hao on 15/12/2022.
//

import SwiftUI

struct ContentView: View {
    
    @State private var typing = false
    @State private var text = ""
    @State private var messages = [["account":"placeholder", "message":""]]
    
    var body: some View {
        VStack {
            HStack {
                Text("Bob 🤖")
            }
                .font(.title2)
                .fontWeight(.bold)
            ScrollView {
                    ForEach(messages, id: \.self) { message in
                        if message["account"]! == "placeholder" {
                            
                        } else if message["account"]! == "bot" {
                            HStack {
                                SpeechBubble(text: Text(message["message"]!), fillColor: Color.purple)
                                    .foregroundColor(.white)
                            }
                        } else {
                            SpeechBubble(text: Text(message["message"]!), fillColor: Color.gray)
                                .foregroundColor(.white)
                        }
                    }
            }
            HStack {
                TextField("Type Here", text: $text).disabled(typing)
                Button {
                    Task.init{ await createMessage() }
                } label: {
                    Text("Send")
                }
                .disabled(text == "" || typing)
                .buttonStyle(.borderedProminent)
            }
            .padding()

        }
    }
    
    func createMessage() async {
        let message = text
        messages.append(["account":"user", "message":"\(message)"])
        text = ""
        typing = true
        try! await Task.sleep(nanoseconds: 400000000)
        Task.init{
            let botResponse = await TokenGenerator().chatWithBot(message: message)
            print(botResponse)
            messages.append(["account":"bot", "message":"\(botResponse)"])
            text = ""
        }
        typing = false
    }
}

struct SpeechBubble: View {
    let text: Text
    let fillColor: Color

    var body: some View {
        Group {
            if fillColor == .purple {
                // Align purple speech bubbles to the left
                HStack {
                    VStack(alignment: .leading) {
                        text
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(fillColor)
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    Spacer()
                }
            } else {
                // Align gray speech bubbles to the right
                HStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        text
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(fillColor)
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
