export interface StoredPhoto {
    key: string;
    url: string;
}
export declare const storage: {
    /**
     * Process & store a submitted photo. The raw photo is what the vitrail shows,
     * so it is NOT tinted. EXIF (incl. GPS) is stripped: sharp drops metadata by
     * default; .rotate() bakes orientation first so we can discard the tag.
     */
    uploadPhoto(rawBuffer: Buffer, userId: string, photoId: string): Promise<StoredPhoto>;
    deletePhoto(key: string): Promise<void>;
    /** Remove every object under a user's prefix (RGPD erasure). */
    deleteUserPhotos(userId: string): Promise<void>;
};
//# sourceMappingURL=storage.d.ts.map