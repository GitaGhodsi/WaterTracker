import SwiftUI

struct GoalSheet: View {
    @Binding var dailyGoal: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Goal")
                .font(.title2.bold())

            Stepper("Glasses: \(dailyGoal)", value: $dailyGoal, in: 1...20)
                .padding()

            Spacer()
        }
        .padding()
    }
}

