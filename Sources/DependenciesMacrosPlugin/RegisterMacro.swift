import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct RegisterMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments.as(TupleExprElementListSyntax.self),
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
        let extensionCode = """
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

        return [DeclSyntax(stringLiteral: extensionCode)]
    }
}


private extension String {
    func prefixLowercased() -> String {
        guard let first = first else { return self }
        return first.lowercased() + dropFirst()
    }
}
