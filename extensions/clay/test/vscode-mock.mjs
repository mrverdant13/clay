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

class Uri {
  /** @param {string} fsPath @param {string} [scheme] */
  constructor(fsPath, scheme = 'file') {
    this.scheme = scheme;
    this.fsPath = fsPath;
    this.path = fsPath;
  }

  /** @param {string} fsPath */
  static file(fsPath) {
    return new Uri(fsPath);
  }

  /** @param {string} value */
  static parse(value) {
    if (value.startsWith('file://')) {
      return new Uri(value.slice('file://'.length));
    }
    return new Uri(value);
  }

  toString() {
    return `${this.scheme}://${this.fsPath}`;
  }
}

/**
 * @param {string} text
 * @param {string} [fileName]
 * @param {{ isDirty?: boolean, saveResult?: boolean }} [options]
 */
export function createMockDocument(text, fileName = '/project/lib/main.dart', options = {}) {
  const lines = text.split('\n');
  const lineStarts = [];
  let offset = 0;
  for (const line of lines) {
    lineStarts.push(offset);
    offset += line.length + 1;
  }

  const uri = Uri.file(fileName);
  let isDirty = options.isDirty ?? false;
  const saveResult = options.saveResult ?? true;

  return {
    fileName,
    languageId: 'dart',
    uri,
    get isDirty() {
      return isDirty;
    },
    set isDirty(value) {
      isDirty = value;
    },
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
      if (!saveResult) {
        return false;
      }
      isDirty = false;
      return true;
    },
  };
}

/** @param {string} text @param {string} [fileName] @param {{ isDirty?: boolean, saveResult?: boolean }} [options] */
export function createMockEditor(text, fileName, options) {
  const document = createMockDocument(text, fileName, options);
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

/** @param {Record<string, unknown>} [initial] */
export function createMockExtensionContext(initial = {}) {
  const state = new Map(Object.entries(initial));
  const subscriptions = [];

  return {
    subscriptions,
    globalState: {
      get(key) {
        return state.get(key);
      },
      async update(key, value) {
        state.set(key, value);
      },
    },
    _state: state,
  };
}

/**
 * Installs a minimal `vscode` module mock for compiled extension helpers.
 * @param {Record<string, unknown>} [overrides]
 */
export function installVscodeMock(overrides = {}) {
  const foldingProviders = [];
  const registeredCommands = [];
  const subscriptions = [];
  const warningMessages = [];
  const executedCommands = [];
  const openedDocuments = [];
  const configuration = new Map();

  const mockVscode = {
    Uri,
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
      showWarningMessage: (message) => {
        warningMessages.push(message);
      },
      showErrorMessage: () => {},
      withProgress: async (_options, task) => task(),
    },
    workspace: {
      isTrusted: true,
      workspaceFolders: undefined,
      getConfiguration: (section) => ({
        get: (key, defaultValue) => {
          const fullKey = `${section}.${key}`;
          return configuration.has(fullKey)
            ? configuration.get(fullKey)
            : defaultValue;
        },
        update: async (key, value) => {
          configuration.set(`${section}.${key}`, value);
        },
      }),
      onDidChangeConfiguration: () => ({ dispose: () => {} }),
      onDidChangeTextDocument: () => ({ dispose: () => {} }),
      onDidOpenTextDocument: () => ({ dispose: () => {} }),
      openTextDocument: async (target) => {
        if (typeof target === 'string' || target instanceof Uri) {
          const uri = typeof target === 'string' ? Uri.parse(target) : target;
          const document = createMockDocument('', uri.fsPath);
          openedDocuments.push({ kind: 'uri', uri, document });
          return document;
        }

        const document = createMockDocument(target.content ?? '', 'untitled:preview', {
          isDirty: false,
        });
        document.languageId = target.language ?? 'dart';
        openedDocuments.push({ kind: 'content', target, document });
        return document;
      },
    },
    commands: {
      registerCommand: (id, handler) => {
        registeredCommands.push({ id, handler });
        return { dispose: () => {} };
      },
      executeCommand: async (command, ...args) => {
        executedCommands.push({ command, args });
      },
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
    warningMessages,
    executedCommands,
    openedDocuments,
    configuration,
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
