const vscode = require('vscode');

const tokenTypes = ['class', 'interface', 'enum', 'function', 'variable', 'keyword', 'string', 'number', 'comment', 'operator', 'parameter'];
const tokenModifiers = ['declaration', 'documentation'];

const legend = new vscode.SemanticTokensLegend(tokenTypes, tokenModifiers);

const provider = {
    provideDocumentSemanticTokens(document) {
        const tokensBuilder = new vscode.SemanticTokensBuilder(legend);
        const text = document.getText();

        // Simple regex-based tokenizer
        const simpleRegex = /(\/\/.*)|(\/\*[\s\S]*?\*\/)|("(?:[^"\\]|\\.)*")|(\b\d+\b)|(\b[a-zA-Z_][a-zA-Z0-9_]*\b)/g;

        let match;
        while ((match = simpleRegex.exec(text))) {
            const tokenText = match[0];
            const startPos = document.positionAt(match.index);

            if (match[1] || match[2]) { // Comment
                // Handle multiline comments by splitting them
                const lines = tokenText.split(/\r\n|\r|\n/);
                let currentOffset = match.index;
                for (let i = 0; i < lines.length; i++) {
                    const lineText = lines[i];
                    if (lineText.length > 0) {
                        const lineStartPos = document.positionAt(currentOffset);
                        tokensBuilder.push(lineStartPos.line, lineStartPos.character, lineText.length, 'comment', 0);
                    }
                    // Calculate offset for next line (including newline char)
                    // This is an approximation, exact newline length depends on the file
                    // But positionAt should handle it if we just increment by length + 1 (or 2 for CRLF)
                    // Actually, simpler: just use document.positionAt for each line start if we knew the exact indices
                    // But since we split the string, we lose the exact newline chars.
                    // A better way for multiline is to just iterate the lines of the match.

                    // Let's rely on the fact that we are just highlighting.
                    // If we get offsets wrong for multiline comments, it might be slightly off.
                    // For safety, let's just highlight the first line of a multiline comment or skip complex multiline logic for this simple regex.
                    // Actually, let's just do single line comments and block comments that are on one line for now to be safe, 
                    // or just push the whole thing if it's on one line.
                    // If it spans multiple lines, SemanticTokensBuilder needs multiple pushes.

                    // Re-evaluating: The regex `(\/\*[\s\S]*?\*\/)` matches the whole block.
                    // If it spans lines, `tokensBuilder.push` will throw if we try to push a multiline range?
                    // VS Code API says: "The range of the token must be single-line."

                    // So we MUST split it.
                    // Let's just re-scan the comment text for newlines.
                }

                // Correct approach for multiline tokens:
                const linesInToken = tokenText.split(/\r\n|\r|\n/);
                let currentLine = startPos.line;
                let currentChar = startPos.character;

                for (let i = 0; i < linesInToken.length; i++) {
                    const lineContent = linesInToken[i];
                    if (lineContent.length > 0) {
                        tokensBuilder.push(currentLine, currentChar, lineContent.length, 'comment', 0);
                    }
                    currentLine++;
                    currentChar = 0; // Next lines start at 0
                }
                continue;
            }

            if (match[3]) { // String
                // Delegate string highlighting to TextMate grammar to support interpolation
                continue;
            }

            if (match[4]) { // Number
                tokensBuilder.push(startPos.line, startPos.character, tokenText.length, 'number', 0);
                continue;
            }

            if (match[5]) { // Identifier
                if (['if', 'else', 'while', 'for', 'return', 'break', 'continue', 'switch', 'case', 'default', 'var', 'const', 'fun', 'class', 'extends', 'this', 'super', 'print', 'out', 'include', 'is', 'in', 'async', 'await', 'true', 'false'].includes(tokenText)) {
                    tokensBuilder.push(startPos.line, startPos.character, tokenText.length, 'keyword', 0);
                } else if (/^[A-Z]/.test(tokenText)) {
                    tokensBuilder.push(startPos.line, startPos.character, tokenText.length, 'class', 0);
                } else {
                    // Check if it's a function call
                    const nextCharIndex = match.index + tokenText.length;
                    const remainingText = text.slice(nextCharIndex);
                    if (/^\s*\(/.test(remainingText)) {
                        tokensBuilder.push(startPos.line, startPos.character, tokenText.length, 'function', 0);
                    } else {
                        tokensBuilder.push(startPos.line, startPos.character, tokenText.length, 'variable', 0);
                    }
                }
                continue;
            }
        }

        return tokensBuilder.build();
    }
};

function activate(context) {
    context.subscriptions.push(vscode.languages.registerDocumentSemanticTokensProvider({ language: 'ochescript' }, provider, legend));
}

exports.activate = activate;
