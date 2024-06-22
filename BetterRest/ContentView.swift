//
//  ContentView.swift
//  BetterRest
//
//  Created by Toine Riedo on 17.06.2024.
//

import CoreML
import EventKit
import SwiftUI



extension Color {
	
	static var random: Color {
		
		let red = Double.random(in: 0...1)
		
		let green = Double.random(in: 0...1)
		
		let blue = Double.random(in: 0...1)
		
		return Color(red: red, green: green, blue: blue)
		
	}
	
}

struct ContentView: View {
	
	static var defaultWakeTime: Date{
		var components = DateComponents()
		components.hour = 7
		components.minute = 0
		return Calendar.current.date(from: components) ?? .now
	}
	var calculatedBedTime: String {
		calculateBedTime()
	}
	
	@State private var sleepAmount = 8.0
	@State private var coffeeAmount = 1
	@State private var wakeUp = defaultWakeTime
	@State private var alertMessage = "Sorry, something went wrong..."
	@State private var alertTitle = "Error"
	@State private var alertShow = false
	
	var body: some View {
		NavigationStack(){
			Form {
				Section(header: Text("When you do you want to wake up ?")){
					HStack{
						DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
							.labelsHidden()
						Spacer()
						Button("Set an alarm ?", action: setAlarm)
							.foregroundColor(.primary)
							.padding()
							.background(.blue)
							.font(.callout)
							.clipShape(Capsule())
						
					}
					
				}
				.listRowBackground(Color.clear)
				
				Section(header: Text("Desired amount of sleep")){
					Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in:4...12, step:0.25)
					if sleepAmount < 5 {
						Text("Be careful not enough sleep isn't healthy...")
							.font(.callout)
					}
				}
				.listRowBackground(Color.clear)
				
				Section(header: Text("Daily coffee intake")) {
					HStack {
						CoffeeLabel(coffeeAmount: $coffeeAmount)
						Picker(selection: $coffeeAmount, label: Text("")) {
							ForEach(1..<21) { number in
								Text("^[\(number) cup](inflect:true)").tag(number)
							}
						}
						.pickerStyle(.menu)
						.tint(coffeeAmount > 10 ? .red : .primary)
					}
					if coffeeAmount > 10 {
						Text("Be careful too much coffee isn't healthy...")
							.font(.callout)
					}
				}
				.listRowBackground(Color.clear)
				
				.listRowBackground(Color.clear)
				
				Section(header: Text("Your recommended bedtime is:")) {
					HStack{
						Spacer()
						Text(calculatedBedTime)
							.font(.largeTitle)
							.fontWeight(.black)
						
						Spacer()
					}
					
				}
				.listRowBackground(Color.clear)
			}
			
			.scrollContentBackground(.hidden) // Hide default content background
			.navigationTitle("BetterRest")
			.alert(alertTitle, isPresented: $alertShow){
				Button("Ok"){
				}
			}message: {
				Text(alertMessage)
			}
		}
		
	}
	
	struct CoffeeLabel: View {
		@Binding var coffeeAmount: Int
		
		var body: some View {
			GeometryReader { geometry in
				let maxMugs = coffeeAmount > 3 ? 3 : coffeeAmount
				let offsetAmount: CGFloat = 10.0
				let totalWidth = CGFloat(maxMugs - 1) * offsetAmount + 45
				let totalHeight = CGFloat(maxMugs - 1) * offsetAmount + 45
				
				ZStack {
					ForEach(0..<maxMugs, id: \.self) { index in
						Image(systemName: "mug.fill")
							.resizable()
							.scaledToFit()
							.frame(width: 45, height: 45)
							.foregroundColor(Color.random)
							.offset(x: CGFloat(index) * offsetAmount,
									y: CGFloat(index) * offsetAmount)
					}
				}
				.frame(width: totalWidth, height: totalHeight)
			}
			.frame(height: 65) // Adjust the height as needed
		}
	}
	
	
	func calculateBedTime() -> String{
		do {
			let config = MLModelConfiguration()
			let model = try SleepCalculator(configuration: config)
			
			let components = Calendar.current.dateComponents([.hour, .minute], from:wakeUp)
			let hour = (components.hour ?? 0) * 60 * 60
			let minute = (components.minute ?? 0) * 60
			let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
			let sleepTime = wakeUp - prediction.actualSleep
			return sleepTime.formatted(date: .omitted, time: .shortened)
		} catch {
			alertTitle = "Error"
			alertMessage = "Sorry, something went wrong."
			alertShow = true
			return "Error"
		}
	}
	
	func setAlarm(){
		print("Print set alarm")
		alertTitle = "Alarm set"
		alertMessage = "Alaram set for \(wakeUp.formatted(date:.omitted,  time: .shortened)) (kidding it doesn't work)"
		alertShow = true
	}
	
	
}

#Preview {
	ContentView()
}
