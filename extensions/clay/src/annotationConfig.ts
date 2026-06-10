import {
  insertedContentBackground,
  insertedMarkerForeground,
  mustacheCommentBackground,
  mustacheDropFlagForeground,
  mustacheTagForeground,
  partialMarkerForeground,
  partialPayloadBackground,
  removedContentBackground,
  removedMarkerForeground,
  replaceBoundaryMarkerForeground,
  replaceOriginalBackground,
  replaceReplacementBackground,
  replaceWithMarkerForeground,
  spacingMarkerBackground,
  spacingMarkerForeground,
} from './annotationColors';

export interface AnnotationConfig {
  remove: {
    markerForeground: string;
    contentBackground: string;
  };
  replace: {
    boundaryMarkerForeground: string;
    withMarkerForeground: string;
    originalBackground: string;
    replacementBackground: string;
  };
  insert: {
    markerForeground: string;
    contentBackground: string;
  };
  partial: {
    markerForeground: string;
    payloadBackground: string;
  };
  mustache: {
    tagForeground: string;
    commentBackground: string;
    dropFlagForeground: string;
  };
  spacing: {
    markerForeground: string;
    markerBackground: string;
  };
}

type SettingReader = (key: string, defaultValue: string) => string;

const DEFAULTS: AnnotationConfig = {
  remove: {
    markerForeground: removedMarkerForeground,
    contentBackground: removedContentBackground,
  },
  replace: {
    boundaryMarkerForeground: replaceBoundaryMarkerForeground,
    withMarkerForeground: replaceWithMarkerForeground,
    originalBackground: replaceOriginalBackground,
    replacementBackground: replaceReplacementBackground,
  },
  insert: {
    markerForeground: insertedMarkerForeground,
    contentBackground: insertedContentBackground,
  },
  partial: {
    markerForeground: partialMarkerForeground,
    payloadBackground: partialPayloadBackground,
  },
  mustache: {
    tagForeground: mustacheTagForeground,
    commentBackground: mustacheCommentBackground,
    dropFlagForeground: mustacheDropFlagForeground,
  },
  spacing: {
    markerForeground: spacingMarkerForeground,
    markerBackground: spacingMarkerBackground,
  },
};

/** Resolves annotation colors from `clay.colors.*` settings with built-in defaults. */
export function resolveAnnotationConfig(readSetting: SettingReader): AnnotationConfig {
  return {
    remove: {
      markerForeground: readSetting(
        'colors.remove.markerForeground',
        DEFAULTS.remove.markerForeground,
      ),
      contentBackground: readSetting(
        'colors.remove.contentBackground',
        DEFAULTS.remove.contentBackground,
      ),
    },
    replace: {
      boundaryMarkerForeground: readSetting(
        'colors.replace.boundaryMarkerForeground',
        DEFAULTS.replace.boundaryMarkerForeground,
      ),
      withMarkerForeground: readSetting(
        'colors.replace.withMarkerForeground',
        DEFAULTS.replace.withMarkerForeground,
      ),
      originalBackground: readSetting(
        'colors.replace.originalBackground',
        DEFAULTS.replace.originalBackground,
      ),
      replacementBackground: readSetting(
        'colors.replace.replacementBackground',
        DEFAULTS.replace.replacementBackground,
      ),
    },
    insert: {
      markerForeground: readSetting(
        'colors.insert.markerForeground',
        DEFAULTS.insert.markerForeground,
      ),
      contentBackground: readSetting(
        'colors.insert.contentBackground',
        DEFAULTS.insert.contentBackground,
      ),
    },
    partial: {
      markerForeground: readSetting(
        'colors.partial.markerForeground',
        DEFAULTS.partial.markerForeground,
      ),
      payloadBackground: readSetting(
        'colors.partial.payloadBackground',
        DEFAULTS.partial.payloadBackground,
      ),
    },
    mustache: {
      tagForeground: readSetting(
        'colors.mustache.tagForeground',
        DEFAULTS.mustache.tagForeground,
      ),
      commentBackground: readSetting(
        'colors.mustache.commentBackground',
        DEFAULTS.mustache.commentBackground,
      ),
      dropFlagForeground: readSetting(
        'colors.mustache.dropFlagForeground',
        DEFAULTS.mustache.dropFlagForeground,
      ),
    },
    spacing: {
      markerForeground: readSetting(
        'colors.spacing.markerForeground',
        DEFAULTS.spacing.markerForeground,
      ),
      markerBackground: readSetting(
        'colors.spacing.markerBackground',
        DEFAULTS.spacing.markerBackground,
      ),
    },
  };
}
