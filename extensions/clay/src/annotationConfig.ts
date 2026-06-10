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

/** Default annotation colors; configurable `clay.colors.*` settings land in a follow-up. */
export function readAnnotationConfig(): AnnotationConfig {
  return {
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
}
