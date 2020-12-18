import React from "react";

interface Props {
    plantProgress: number;
    plantOrDefuse: string|null;
}

const PlantOrDefuseProgress: React.FC<Props> = ({ plantProgress, plantOrDefuse }) => {
    return (
        <>
            {plantProgress > 0 &&
                <div id="pageInGame" className="page">
                    <div className={"infoBox plantOrDefuse " + plantOrDefuse}>
                        <div className="progressHolder">
                            <div className={"rupProgress " + plantOrDefuse} style={{width: plantProgress + "%"}}></div>
                        </div>
                        {(plantOrDefuse === "plant")
                        ?
                            <>
                                <h1>PLANTING</h1>
                            </>
                        :
                            <>
                                <h1>DEFUSING</h1>
                            </>
                        }
                    </div>
                </div>
            }
        </>
    );
};

export default PlantOrDefuseProgress;
