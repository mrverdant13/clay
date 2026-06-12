import Module from 'node:module';

/** @typedef {{ line: number; character: number }} PositionLike */

class Position {
  /** @param {number} line @param {number} character */
  constructor(line, character) {
    this.line = line;
    this.character = character;
  }
}

class Range {
  /** @param {PositionLike} start @param {PositionLike} end */
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }
}

class FoldingRange {
  /** @param {number} start @param {number} end @param {unknown} [kind] */
  constructor(start, end, kind) {
    this.start = start;
    this.end = end;
    this.kind = kind;
  }
}

/**
 * @param {string} text
 * @param {string} [fileName]
 */
export function createMockDocument(text, fileName = '/project/lib/main.dart') {
  const lines = text.split('\n');
  const lineStarts = [];
  let offset = 0;
  for (const line of lines) {
    lineStarts.push(offset);
    offset += line.length + 1;
  }

  return {
    fileName,
    languageId: 'dart',
    uri: { toString: () => `file://${fileName}` },
    isDirty: false,
  /** @param {Range} [range] */
    getText(range) {
      if (range === undefined) {
        return text;
      }
      const start = range.start.line === undefined
        ? range.start
        : lineStarts[range.start.line] + range.start.character;
      const end = range.end.line === undefined
        ? range.end
        : lineStarts[range.end.line] + range.end.character;
      if (typeof start === 'number' && typeof end === 'number') {
        return text.slice(start, end);
      }
      const startOffset = lineStarts[range.start.line] + range.start.character;
      const endOffset = lineStarts[range.end.line] + range.end.character;
      return text.slice(startOffset, endOffset);
    },
    /** @param {number} charOffset */
    positionAt(charOffset) {
      for (let line = 0; line < lines.length; line += 1) {
        const lineStart = lineStarts[line];
        const lineEnd = lineStart + lines[line].length;
        if (charOffset <= lineEnd) {
          return new Position(line, charOffset - lineStart);
        }
      }
      const lastLine = Math.max(0, lines.length - 1);
      return new Position(lastLine, lines[lastLine]?.length ?? 0);
    },
    /** @param {PositionLike} position */
    offsetAt(position) {
      return lineStarts[position.line] + position.character;
    },
    /** @param {number | { line: number }} lineOrPosition */
    lineAt(lineOrPosition) {
      const line =
        typeof lineOrPosition === 'number'
          ? lineOrPosition
          : lineOrPosition.line;
      const content = lines[line] ?? '';
      return {
        text: content,
        range: new Range(
          new Position(line, 0),
          new Position(line, content.length),
        ),
      };
    },
    async save() {
      return true;
    },
  };
}

/** @param {string} text @param {string} [fileName] */
export function createMockEditor(text, fileName) {
  const document = createMockDocument(text, fileName);
  const decorationCalls = [];

  return {
    document,
    /** @param {unknown} type @param {readonly Range[]} ranges */
    setDecorations(type, ranges) {
      decorationCalls.push({ type, ranges });
    },
    decorationCalls,
  };
}

/** @param {Array<{ type: unknown; ranges: readonly Range[] }>} calls @param {number} index */
export function rangesText(document, calls, index) {
  const text = document.getText();
  const { ranges } = calls[index];
  return ranges.map((range) => {
    const start = document.offsetAt(range.start);
    const end = document.offsetAt(range.end);
    return text.slice(start, end);
  });
}

/**
 * Installs a minimal `vscode` module mock for compiled extension helpers.
 * @param {Record<string, unknown>} [overrides]
 */
export function installVscodeMock(overrides = {}) {
  const foldingProviders = [];
  const registeredCommands = [];
  const subscriptions = [];

  const mockVscode = {
    Range,
    Position,
    FoldingRange,
    FoldingRangeKind: { Region: 'region' },
    window: {
      visibleTextEditors: [],
      activeTextEditor: undefined,
      createTextEditorDecorationType: (options) => ({
        options,
        dispose: () => {},
      }),
      onDidChangeActiveTextEditor: () => ({ dispose: () => {} }),
      showQuickPick: async () => undefined,
      showInputBox: async () => undefined,
      showWarningMessage: () => {},
      showErrorMessage: () => {},
      withProgress: async (_options, task) => task(),
    },
    workspace: {
      getConfiguration: () => ({
        get: (_key, defaultValue) => defaultValue,
      }),
      onDidChangeConfiguration: () => ({ dispose: () => {} }),
      onDidChangeTextDocument: () => ({ dispose: () => {} }),
      onDidOpenTextDocument: () => ({ dispose: () => {} }),
      openTextDocument: async (uri) => uri,
    },
    commands: {
      registerCommand: (id, handler) => {
        registeredCommands.push({ id, handler });
        return { dispose: () => {} };
      },
      executeCommand: async () => {},
    },
    languages: {
      registerFoldingRangeProvider: (_selector, provider) => {
        foldingProviders.push(provider);
        return { dispose: () => {} };
      },
    },
    ProgressLocation: { Notification: 15 },
    Disposable: class {
      /** @param {() => void} callBack */
      constructor(callBack) {
        this.dispose = callBack;
      }
    },
    ...overrides,
  };

  if (!installVscodeMock.installed) {
    const originalLoad = Module._load;
    Module._load = function load(request, parent, isMain) {
      if (request === 'vscode') {
        return installVscodeMock.mockVscode;
      }
      return originalLoad.call(this, request, parent, isMain);
    };
    installVscodeMock.installed = true;
  }

  installVscodeMock.mockVscode = mockVscode;

  return {
    mockVscode,
    foldingProviders,
    registeredCommands,
    subscriptions,
  };
}

installVscodeMock.installed = false;
/** @type {Record<string, unknown>} */
installVscodeMock.mockVscode = {};

/** Default annotation config for highlighting refresh tests. */
export const defaultAnnotationConfig = {
  remove: {
    markerForeground: '#F48771',
    contentBackground: 'rgba(244, 135, 113, 0.14)',
  },
  replace: {
    boundaryMarkerForeground: '#E5A84B',
    withMarkerForeground: '#4EC9B0',
    originalBackground: 'rgba(229, 168, 75, 0.14)',
    replacementBackground: 'rgba(78, 201, 176, 0.14)',
  },
  insert: {
    markerForeground: '#C586C0',
    contentBackground: 'rgba(197, 134, 192, 0.14)',
  },
  partial: {
    markerForeground: '#569CD6',
    payloadBackground: 'rgba(86, 156, 214, 0.14)',
  },
  mustache: {
    tagForeground: '#C678DD',
    commentBackground: 'rgba(198, 120, 221, 0.10)',
    dropFlagForeground: '#F48771',
  },
  spacing: {
    markerForeground: '#A0A1A7',
    markerBackground: 'rgba(160, 161, 167, 0.12)',
  },
};
