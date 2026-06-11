export interface SegmentedArtwork {
    cols: number;
    rows: number;
    cells: CellData[];
    zones: ZoneData[];
}
export interface CellData {
    index: number;
    col: number;
    row: number;
    zoneId: string;
}
export interface ZoneData {
    id: string;
    pigment: string;
    label: string;
    cellCount: number;
    targetHex: string;
}
export declare function segmentArtwork(imageBuffer: Buffer, numZones?: number): Promise<SegmentedArtwork>;
export declare function evocativeName(r: number, g: number, b: number): string;
//# sourceMappingURL=segmentation.d.ts.map