import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

//@main
//struct DependencyMacroPlugin: CompilerPlugin {
//    let providingMacros: [Macro.Type] = [RegisterMacro.self]
//}

public struct RegisterMacro: ExpressionMacro {
  public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        guard let arguments = node.argumentList.as(TupleExprElementListSyntax.self),
              arguments.count == 2,
              let protocolType = arguments.first?.expression.as(IdentifierExprSyntax.self)?.identifier.text,
              let concreteType = arguments.last?.expression.as(FunctionCallExprSyntax.self)?.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text
        else {
          throw DiagnosticsError(
            diagnostics: [
              Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage(
                  """
                  Invalid arguments. Expected format: #register(ProtocolType, ConcreteType())
                  """
                )
              )
            ]
          )
        }

        let dependencyKeyName = "\(protocolType)DependencyKey"
        let output = """
        public extension DependencyValues {
            private enum \(dependencyKeyName): DependencyKey {
                static var liveValue: \(protocolType) = \(concreteType)()
            }
            
            var \(protocolType.prefixLowercased()): \(protocolType) {
                get { self[\(dependencyKeyName).self] }
                set { self[\(dependencyKeyName).self] = newValue }
            }
        }
        """
        
        return ExprSyntax(stringLiteral: output)
    }
}

private extension String {
    func prefixLowercased() -> String {
        guard let first = first else { return self }
        return first.lowercased() + dropFirst()
    }
}
