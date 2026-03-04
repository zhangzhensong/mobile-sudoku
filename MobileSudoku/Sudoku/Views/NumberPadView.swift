import SwiftUI

struct NumberPadView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...9, id: \.self) { num in
                let done = vm.completedNumbers.contains(num)
                Button {
                    vm.inputNumber(num)
                } label: {
                    Text("\(num)")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(done ? Color(.systemGray3) : .primary)
                }
                .disabled(done)
            }
        }
    }
}
