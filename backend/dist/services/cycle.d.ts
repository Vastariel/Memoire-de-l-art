export interface IsoWeek {
    year: number;
    week: number;
}
/** ISO-8601 week number (UTC). */
export declare function isoWeek(d?: Date): IsoWeek;
/** Day of week, Monday=1 … Sunday=7 (UTC). */
export declare function weekDay(d?: Date): number;
export declare function artworkId({ year, week }: IsoWeek): string;
export interface ArtworkRow {
    id: string;
    title_fr: string | null;
    title_en: string | null;
    artist: string | null;
    year_: number | null;
    description_fr: string | null;
    description_en: string | null;
    cols: number;
    rows: number;
    cells: unknown;
    hd_url: string | null;
    status: string;
    iso_year: number;
    iso_week: number;
}
/** The week's artwork (active or revealed) for the given/current date, or null. */
export declare function currentArtwork(at?: Date): Promise<ArtworkRow | null>;
/** Monday 00:00 UTC — promote the week's planned artwork to active. */
export declare function activateCurrentWeek(): Promise<void>;
/** Sunday 23:59 UTC — resolve guesses, award bet points, reveal the artwork. */
export declare function revealCurrentWeek(): Promise<void>;
/** Public-facing metadata is hidden until the artwork is revealed. */
export declare function publicArtwork(a: ArtworkRow, locale: string): {
    id: string;
    cols: number;
    rows: number;
    cells: unknown;
    status: string;
    isoYear: number;
    isoWeek: number;
    title: string | null;
    artist: string | null;
    year: number | null;
    description: string | null;
    hdUrl: string | null;
};
//# sourceMappingURL=cycle.d.ts.map