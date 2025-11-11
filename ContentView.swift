//
//  ContentView.swift
//  WaterTracker
//
//  Created by Gita Ghodsi on 06/11/25.
//


import SwiftUI

struct ContentView: View {
    @AppStorage("dailyGoal") private var dailyGoal: Int = 8
    @AppStorage("todayCount") private var todayCount: Int = 0
    @AppStorage("lastOpenedDate") private var lastOpenedDate: String = ""

    @State private var showGoalSheet = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Water Tracker")
                .font(.largeTitle.bold())

            // Progress Section
            VStack(spacing: 12) {
                Text("\(todayCount) / \(dailyGoal)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                
                ProgressView(value: Double(todayCount), total: Double(dailyGoal))
                    .tint(.blue)
                    .padding(.horizontal, 40)
            }

            // Buttons
            HStack(spacing: 24) {
                Button(action: decrement) {
                    Text("−1")
                        .font(.largeTitle.bold())
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)

                Button(action: increment) {
                    Text("+1")
                        .font(.largeTitle.bold())
                        .frame(width: 80, height: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            // Change goal sheet
            Button("Set Daily Goal") {
                showGoalSheet = true
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .onAppear(perform: resetIfNewDay)
        .sheet(isPresented: $showGoalSheet) {
            GoalSheet(dailyGoal: $dailyGoal)
        }
    }

    private func increment() {
        if todayCount < dailyGoal {
            todayCount += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func decrement() {
        if todayCount > 0 {
            todayCount -= 1
        }
    }

    private func resetIfNewDay() {
        let today = formattedDate(Date())
        if lastOpenedDate != today {
            todayCount = 0
            lastOpenedDate = today
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
