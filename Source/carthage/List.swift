//
//  List.swift
//  Carthage
//
//  Created by William Izzo on 02/05/2017.
//  Copyright © 2017 Carthage. All rights reserved.
//

import CarthageKit
import Commandant
import Foundation
import Result
import ReactiveSwift

public struct ListCommand: CommandProtocol {
	public let verb = "list"
	public let function = "Resolves Cartfile and lists all project's dependencies."
	
	public struct Options: OptionsProtocol {
		public let useSSH: Bool
		public let showPath: Bool
		public let showVersion: Bool
		
		public static func create(_ useSSH: Bool) -> (Bool) -> (Bool) -> Options {
			return { showPath in { showVersion in
				return self.init(useSSH: useSSH, showPath:showPath, showVersion:showVersion)
				} }
		}
		
		public static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<CarthageError>> {
			return create
				<*> m <| Option(key: "use-ssh", defaultValue: false, usage: "use SSH for downloading GitHub repositories")
				<*> m <| Option(key: "show-paths", defaultValue:false, usage: "show dependencies install path")
				<*> m <| Option(key: "show-versions", defaultValue:false, usage: "show dependencies version")
		}
		
		public func loadProject() -> SignalProducer<Project, CarthageError> {
			let directoryURL = URL(fileURLWithPath: "", isDirectory: true)
			let project = Project(directoryURL: directoryURL)
			project.preferHTTPS = !self.useSSH
			return SignalProducer(value:project)
		}
	}
	
	
	public func run(_ options: ListCommand.Options) -> Result<(), CarthageError> {
		return options.loadProject()
			.flatMap(.merge) { project -> SignalProducer<(), CarthageError> in
				let loadCartfile = project.updatedResolvedCartfile()
					.flatMap(.concat) { resolvedCartfile -> SignalProducer<(), CarthageError> in
						let dependencyList = resolvedCartfile.dependencies.map {
							($0.key.name, $0.key.relativePath, $0.value.commitish)
						}
						
						for dependency in dependencyList {
							print(dependency.0)
							if options.showPath {
								print(" \(dependency.1)")
							}
							
							if options.showVersion {
								print(" \(dependency.2)")
							}
							
							println("")
						}
						
						return .empty
				}
				return loadCartfile
		}.waitOnCommand()
 		
	}
}
